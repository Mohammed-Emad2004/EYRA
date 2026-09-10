import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/detection_log.dart';
import '../../models/obstacle.dart';
import '../obstacle_detection_service.dart';
import 'ai_config.dart';
import 'jpeg_encoder.dart';

/// HTTP implementation of [ObstacleDetectionService].
///
/// Wires the camera image stream to the EYRA AI Flask service.
/// When [start] is called, it subscribes to [cameraStream] and — on the
/// first frame — fires a single POST /api/detect request.  Subsequent
/// detections are triggered by calling [detect] directly (e.g. from a
/// UI button) or by enabling the [autoDetect] flag after the initial
/// single-frame integration is proven stable.
///
/// All network errors are caught and logged; the app never crashes due to
/// AI service unavailability.
///
/// Construction site: [main.dart] — injected into [AssistanceController].
class HttpObstacleDetectionService implements ObstacleDetectionService {
  /// [cameraStream] — the frame stream from [EyraCameraController.imageStream].
  /// [sessionId]   — propagated to every emitted [DetectionLog].
  /// [client]      — injectable for testing; defaults to a shared instance.
  HttpObstacleDetectionService({
    required Stream<CameraImage> cameraStream,
    String? sessionId,
    http.Client? client,
  })  : _cameraStream = cameraStream,
        _sessionId = sessionId ?? 'http-session',
        _client = client ?? http.Client() {
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService CONSTRUCTED '
      '(instance=${identityHashCode(this)}, cameraStream=${identityHashCode(_cameraStream)}, '
      'sessionId=$_sessionId)',
    );
  }

  final Stream<CameraImage> _cameraStream;
  final String _sessionId;
  final http.Client _client;

  final _outController = StreamController<DetectionLog>.broadcast();
  final _batchController = StreamController<List<DetectionLog>>.broadcast();
  StreamSubscription<CameraImage>? _cameraSub;
  bool _requesting = false; // overlap guard
  bool _running = false;

  // ── ObstacleDetectionService interface ─────────────────────────────────────

  @override
  bool get isReady => true;

  @override
  Stream<DetectionLog> get detections => _outController.stream;

  @override
  Stream<List<DetectionLog>> get batchDetections => _batchController.stream;

  /// Subscribes to the camera stream and processes the first available
  /// frame.  The service uses a single-frame-per-call model: each
  /// non-overlapping frame triggers one HTTP request.
  @override
  void start() {
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService.start() CALLED '
      '(instance=${identityHashCode(this)}, _running=$_running, '
      '_cameraSub=${_cameraSub != null ? "active" : "null"})',
    );
    if (_running) {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService.start: ALREADY RUNNING, early return');
      return;
    }
    _running = true;
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService.start: subscribing to _cameraStream '
      '(stream=${identityHashCode(_cameraStream)})',
    );
    _cameraSub = _cameraStream.listen((image) {
      debugPrint(
        '[DIAGNOSTIC] HttpObstacleDetectionService: _cameraStream listener fired! '
        'image=${image.width}x${image.height}',
      );
      // Fire-and-forget; overlap is guarded internally.
      _detect(image);
    }, onError: (Object err, StackTrace st) {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService: _cameraStream error: $err');
    }, onDone: () {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService: _cameraStream done/closed');
    });
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService.start: _cameraSub attached successfully? ${_cameraSub != null}',
    );
  }

  @override
  void stop() {
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService.stop() CALLED (instance=${identityHashCode(this)})',
    );
    _running = false;
    _requesting = false;
    _cameraSub?.cancel();
    _cameraSub = null;
  }

  // ── Detection ─────────────────────────────────────────────────────────────

  Future<void> _detect(CameraImage image) async {
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService._detect() FIRST LINE CALLED! '
      'frame=${image.width}x${image.height}, instance=${identityHashCode(this)}',
    );
    debugPrint(
      '[DIAGNOSTIC] HttpObstacleDetectionService._detect: _running=$_running, _requesting=$_requesting',
    );
    if (!_running || _requesting) {
      debugPrint(
        '[DIAGNOSTIC] HttpObstacleDetectionService._detect: SKIPPED (_running=$_running, _requesting=$_requesting)',
      );
      return;
    }
    _requesting = true;
    try {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService._detect: calling JpegEncoder.fromYuv420...');
      final jpeg = JpegEncoder.fromYuv420(image);
      debugPrint(
        '[DIAGNOSTIC] HttpObstacleDetectionService._detect: JpegEncoder returned '
        '${jpeg != null ? "${jpeg.lengthInBytes} bytes" : "NULL"}',
      );
      if (jpeg == null) {
        debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService: frame encode failed (returned null), skipping');
        log('HttpObstacleDetectionService: frame encode failed, skipping');
        return;
      }

      final b64 = 'data:image/jpeg;base64,${base64Encode(jpeg)}';
      const configuredUrl = '${AiConfig.aiBaseUrl}${AiConfig.detectEndpoint}';
      final uri = Uri.parse(configuredUrl);
      debugPrint(
        '[DIAGNOSTIC] HttpObstacleDetectionService._detect: REACHING POST call to: $uri '
        '(configured URL=$configuredUrl, base64 payload length=${b64.length})',
      );

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': b64}),
          )
          .timeout(AiConfig.requestTimeout);

      debugPrint(
        '[DIAGNOSTIC] HttpObstacleDetectionService._detect: POST response status=${response.statusCode}, '
        'body length=${response.body.length}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[DIAGNOSTIC] HttpObstacleDetectionService: HTTP status ${response.statusCode}: ${response.body}',
        );
        log('HttpObstacleDetectionService: HTTP ${response.statusCode}');
        return;
      }

      _parseAndEmit(response.body);
    } on TimeoutException catch (e) {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService: request timed out: $e');
      log('HttpObstacleDetectionService: request timed out');
    } catch (e, st) {
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService: error during _detect / POST: $e\n$st');
      log('HttpObstacleDetectionService: error - $e');
    } finally {
      _requesting = false;
      debugPrint('[DIAGNOSTIC] HttpObstacleDetectionService._detect: finished execution, reset _requesting=false');
    }
  }

  void _parseAndEmit(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      log('HttpObstacleDetectionService: malformed JSON - $e');
      return;
    }

    final rawList = json['detections'];
    if (rawList is! List || rawList.isEmpty) {
      log('HttpObstacleDetectionService: no detections');
      return;
    }

    final entries = <DetectionLog>[];
    for (final raw in rawList) {
      if (raw is! Map<String, dynamic>) continue;
      final entry = _map(raw);
      if (entry != null) {
        entries.add(entry);
        if (!_outController.isClosed) {
          _outController.add(entry);
        }
      }
    }

    if (entries.isNotEmpty && !_batchController.isClosed) {
      _batchController.add(entries);
    }
  }

  // ── API mapping ───────────────────────────────────────────────────────────

  /// Maps one API detection JSON object to a [DetectionLog].
  ///
  /// API fields:
  ///   label    → detectedLabel
  ///   dir_tag  → spatialDirection  (LEFT / CENTER / RIGHT)
  ///   distance → dangerLevel proxy (see TEMPORARY note below)
  ///   conf     → Obstacle.confidence (surfaced via DetectionLog.toObstacle)
  ///
  /// ⚠ TEMPORARY: The /api/detect response does not include `danger_level`.
  ///   Distance (metres) is used as a proxy until the API exposes it:
  ///     ≤ 2 m  → DangerLevel.high   (Distance.near)
  ///     ≤ 4 m  → DangerLevel.medium (Distance.medium)
  ///     > 4 m  → DangerLevel.low    (Distance.far)
  DetectionLog? _map(Map<String, dynamic> d) {
    try {
      final label = (d['label'] as String? ?? '').trim();
      if (label.isEmpty) return null;

      final rawBox = d['box'] ?? d['bounding_box'];
      List<double>? box;
      if (rawBox is List && rawBox.length >= 4) {
        box = [
          (rawBox[0] as num).toDouble(),
          (rawBox[1] as num).toDouble(),
          (rawBox[2] as num).toDouble(),
          (rawBox[3] as num).toDouble(),
        ];
      }

      final origW = (d['orig_w'] as num?)?.toDouble();
      final origH = (d['orig_h'] as num?)?.toDouble();

      final rawTag = d['dir_tag'] ?? d['direction'];
      final SpatialDirection dir;
      if (rawTag != null) {
        dir = _parseDirection(rawTag.toString().toUpperCase());
      } else if (box != null && box.length >= 4) {
        final w = (origW != null && origW > 0)
            ? origW
            : (box[2] > 1.0 ? 640.0 : 1.0);
        if (box[2] <= 0.25 * w) {
          dir = SpatialDirection.left;
        } else if (box[0] >= 0.75 * w) {
          dir = SpatialDirection.right;
        } else {
          dir = SpatialDirection.center;
        }
      } else {
        dir = SpatialDirection.center;
      }

      final bool isInFront = box != null
          ? checkFrontIntersection(
              box: box,
              imageWidth: origW,
              imageHeight: origH,
            )
          : dir == SpatialDirection.center;

      final distM = (d['distance'] as num?)?.toDouble() ?? 5.0;

      final dangerLevel = distM <= 2.0
          ? DangerLevel.high
          : distM <= 4.0
              ? DangerLevel.medium
              : DangerLevel.low;

      final distance = switch (dangerLevel) {
        DangerLevel.high => Distance.near,
        DangerLevel.medium => Distance.medium,
        DangerLevel.low => Distance.far,
      };

      final conf = (d['conf'] as num?)?.toDouble();

      return DetectionLog.fromObstacle(
        Obstacle(
          label: label,
          direction: dir,
          distance: distance,
          confidence: conf,
          boundingBox: box,
          isInFrontZone: isInFront,
        ),
        id: 'http-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: _sessionId,
        createdAt: DateTime.now(),
        isInFrontZone: isInFront,
        confidence: conf,
      );
    } catch (e) {
      log('HttpObstacleDetectionService: mapping error - $e');
      return null;
    }
  }

  /// Whether the bounding box [x1, y1, x2, y2] enters/intersects the user's
  /// FRONT rectangular detection zone (central 50% horizontal corridor).
  static bool checkFrontIntersection({
    required List<double> box,
    double? imageWidth,
    double? imageHeight,
  }) {
    if (box.length < 4) return false;
    final bx1 = box[0];
    final by1 = box[1];
    final bx2 = box[2];
    final by2 = box[3];

    final double w = (imageWidth != null && imageWidth > 0)
        ? imageWidth
        : (bx2 > 1.0 ? 640.0 : 1.0);
    final double h = (imageHeight != null && imageHeight > 0)
        ? imageHeight
        : (by2 > 1.0 ? 480.0 : 1.0);

    // Front rectangular zone: central 50% horizontal field of attention [0.25*w, 0.75*w], full height [0, h]
    final frontLeft = 0.25 * w;
    final frontRight = 0.75 * w;
    const frontTop = 0.0;
    final frontBottom = h;

    return bx2 > frontLeft && bx1 < frontRight && by2 > frontTop && by1 < frontBottom;
  }

  SpatialDirection _parseDirection(String tag) => switch (tag) {
        'LEFT' => SpatialDirection.left,
        'RIGHT' => SpatialDirection.right,
        _ => SpatialDirection.center,
      };

  // ── Disposal ──────────────────────────────────────────────────────────────

  void dispose() {
    stop();
    if (!_outController.isClosed) _outController.close();
    if (!_batchController.isClosed) _batchController.close();
    _client.close();
  }
}
