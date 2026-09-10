import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assistance_session.dart';
import '../models/detection_log.dart';
import '../models/obstacle.dart';
import '../services/assistance_service.dart';
import '../services/detection_log_service.dart';
import '../services/mock/mock_assistance_service.dart';
import '../services/mock/mock_detection_log_service.dart';
import '../services/mock/mock_obstacle_detection_service.dart';
import '../services/obstacle_detection_service.dart';
import '../services/text_to_speech_service.dart';
import 'app_settings_controller.dart';

/// Live-assistance session state shared across Home and Live Assistance
/// screens.
///
/// This controller is the abstraction boundary those screens depend on.
/// It never talks to a real (or mock) detector or session store
/// directly - it coordinates an injected [AssistanceService] (session
/// lifecycle), an injected [ObstacleDetectionService] (detections),
/// an optional [TextToSpeechService] (spoken alerts), and an optional
/// [AppSettingsController] (language and accessibility preferences).
class AssistanceController extends ChangeNotifier {
  AssistanceController({
    AssistanceService? assistanceService,
    ObstacleDetectionService? detectionService,
    DetectionLogService? detectionLogService,
    TextToSpeechService? textToSpeechService,
    AppSettingsController? settingsController,
    double speechConfidenceThreshold = defaultSpeechConfidenceThreshold,
    int requiredStableFrames = defaultRequiredStableFrames,
  })  : _assistanceService = assistanceService ?? MockAssistanceService(),
        _detectionService = detectionService ?? MockObstacleDetectionService(),
        _detectionLogService = detectionLogService ?? MockDetectionLogService(),
        _textToSpeechService = textToSpeechService,
        _settingsController = settingsController,
        _speechConfidenceThreshold = speechConfidenceThreshold,
        _requiredStableFrames = requiredStableFrames {
    _detectionSubscription =
        _detectionService.batchDetections.listen(_onDetections);
  }

  static const double defaultSpeechConfidenceThreshold = 0.45;
  static const int defaultRequiredStableFrames = 2;
  static const Duration _stabilityWindow = Duration(seconds: 2);

  final AssistanceService _assistanceService;
  final ObstacleDetectionService _detectionService;
  final DetectionLogService _detectionLogService;
  final TextToSpeechService? _textToSpeechService;
  final AppSettingsController? _settingsController;
  final double _speechConfidenceThreshold;
  final int _requiredStableFrames;
  late final StreamSubscription<List<DetectionLog>> _detectionSubscription;

  bool _isAssistanceActive = false;
  AssistanceSession? _currentSession;
  List<DetectionLog> _latestDetections = [];
  final Map<String, DateTime> _speechCooldowns = {};
  final Map<String, int> _consecutiveFrameHits = {};
  final Map<String, DateTime> _lastSeenTimestamps = {};
  static const Duration _speechCooldown = Duration(seconds: 4);
  String? _lastConfiguredLocale;

  double get speechConfidenceThreshold => _speechConfidenceThreshold;
  int get requiredStableFrames => _requiredStableFrames;

  static const Map<String, String> _arabicObjectNames = {
    'person': 'شخص',
    'car': 'سيارة',
    'chair': 'كرسي',
    'bicycle': 'دراجة',
    'motorcycle': 'دراجة نارية',
    'bus': 'حافلة',
    'truck': 'شاحنة',
    'traffic light': 'إشارة مرور',
    'stop sign': 'إشارة توقف',
    'bench': 'مقعد',
    'dog': 'كلب',
    'cat': 'قطة',
    'door': 'باب',
    'stairs': 'درج',
    'table': 'طاولة',
    'dining table': 'طاولة',
    'couch': 'أريكة',
    'sofa': 'أريكة',
    'bed': 'سرير',
    'backpack': 'حقيبة ظهر',
    'umbrella': 'مظلة',
    'handbag': 'حقيبة يد',
    'suitcase': 'حقيبة سفر',
    'bottle': 'زجاجة',
    'cup': 'كوب',
    'tv': 'تلفاز',
    'laptop': 'حاسوب',
    'cell phone': 'هاتف',
  };

  bool get isAssistanceActive => _isAssistanceActive;
  AssistanceSession? get currentSession => _currentSession;
  DetectionLog? get latestDetectionLog =>
      _latestDetections.isNotEmpty ? _latestDetections.first : null;
  List<DetectionLog> get latestDetectionLogs => _latestDetections;

  /// The current detection translated to the existing [Obstacle] UI
  /// model, so Home/Live Assistance/ObstacleCard keep working unchanged.
  Obstacle? get latestObstacle =>
      _latestDetections.isNotEmpty ? _latestDetections.first.toObstacle() : null;

  /// All current detections from the latest frame translated to [Obstacle]s.
  List<Obstacle> get latestObstacles =>
      _latestDetections.map((d) => d.toObstacle()).toList();

  /// Whether the underlying obstacle detector (mock or a real model) is
  /// ready to run.
  bool get isDetectorReady => _detectionService.isReady;

  static AssistanceController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AssistanceController>(context, listen: listen);
  }

  Future<void> startAssistance() async {
    debugPrint(
      '[DIAGNOSTIC] AssistanceController.startAssistance() CALLED '
      '(controller=${identityHashCode(this)}, detectionService=${identityHashCode(_detectionService)})',
    );
    _isAssistanceActive = true;
    _latestDetections = [];
    _speechCooldowns.clear();
    _consecutiveFrameHits.clear();
    _lastSeenTimestamps.clear();
    _lastConfiguredLocale = null;
    debugPrint('[DIAGNOSTIC] AssistanceController: calling _detectionService.start()');
    _detectionService.start();
    debugPrint('[DIAGNOSTIC] AssistanceController: _detectionService.start() returned');
    notifyListeners();

    try {
      _currentSession = await _assistanceService.startSession();
    } catch (e) {
      debugPrint('AssistanceController: session start error - $e');
    }
  }

  Future<void> stopAssistance() async {
    _detectionService.stop();
    _isAssistanceActive = false;
    final session = _currentSession;
    _currentSession = null;
    _latestDetections = [];
    _speechCooldowns.clear();
    _consecutiveFrameHits.clear();
    _lastSeenTimestamps.clear();
    _lastConfiguredLocale = null;
    await _textToSpeechService?.stop();
    notifyListeners();
    if (session != null) {
      await _assistanceService.stopSession(session.sessionId);
    }
  }

  void _onDetections(List<DetectionLog> logs) {
    if (logs.isEmpty) return;
    _latestDetections = logs;
    notifyListeners();

    _handleSpeech(logs);

    if (_currentSession != null) {
      for (final log in logs) {
        unawaited(
          _detectionLogService
              .logDetection(
                sessionId: _currentSession!.sessionId,
                log: log,
              )
              .catchError((Object e) {
            debugPrint('Detection log persistence failed: $e');
          }),
        );
      }
    }
  }

  /// Speaks detected objects that:
  /// 1. Meet the confidence threshold (>= [_speechConfidenceThreshold]).
  /// 2. Enter/intersect the user's FRONT attention rectangle ([isInFrontZone]).
  /// 3. Demonstrate temporal stability across consecutive frames ([_requiredStableFrames]).
  ///
  /// Objects outside the FRONT rectangle or below threshold are not spoken.
  /// Left/right directional phrasing is omitted.
  void _handleSpeech(List<DetectionLog> logs) {
    final tts = _textToSpeechService;
    if (tts == null) return;

    final isVoiceAlertsEnabled = _settingsController?.voiceAlerts ?? true;
    if (!isVoiceAlertsEnabled) return;

    // 1. Filter detections that are inside/intersecting the FRONT rectangle
    // AND meet the confidence threshold (or if confidence is null for mock/unannotated data).
    final eligibleLogs = logs.where((l) {
      if (!l.isInFrontZone) return false;
      if (l.confidence != null && l.confidence! < _speechConfidenceThreshold) {
        return false;
      }
      return true;
    }).toList();

    if (eligibleLogs.isEmpty) return;

    final now = DateTime.now();

    // 2. Track temporal stability: update consecutive frame hits for candidates.
    final currentFrameKeys = <String>{};
    for (final log in eligibleLogs) {
      final rawLabel = log.detectedLabel.trim();
      if (rawLabel.isNotEmpty) {
        currentFrameKeys.add(rawLabel.toLowerCase());
      }
    }

    for (final key in currentFrameKeys) {
      final lastSeen = _lastSeenTimestamps[key];
      if (lastSeen != null && now.difference(lastSeen) <= _stabilityWindow) {
        _consecutiveFrameHits[key] = (_consecutiveFrameHits[key] ?? 1) + 1;
      } else {
        _consecutiveFrameHits[key] = 1;
      }
      _lastSeenTimestamps[key] = now;
    }

    // Prune stale stability entries outside the window
    _lastSeenTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _stabilityWindow) {
        _consecutiveFrameHits.remove(key);
        return true;
      }
      return false;
    });

    // 3. Filter for detections that meet the required consecutive stable frames.
    final stableLogs = eligibleLogs.where((l) {
      final key = l.detectedLabel.trim().toLowerCase();
      final hits = _consecutiveFrameHits[key] ?? 0;
      return hits >= _requiredStableFrames;
    }).toList();

    if (stableLogs.isEmpty) return;

    final eligibleLabels = <String>[];
    final seenLabelsThisFrame = <String>{};

    for (final log in stableLogs) {
      final rawLabel = log.detectedLabel.trim();
      if (rawLabel.isEmpty) continue;

      final normalizedKey = rawLabel.toLowerCase();
      // Deduplicate identical objects within the same frame
      if (!seenLabelsThisFrame.add(normalizedKey)) continue;

      // Check cooldown for this object type so we don't repeat every frame
      final lastTime = _speechCooldowns[normalizedKey];
      if (lastTime == null || now.difference(lastTime) > _speechCooldown) {
        _speechCooldowns[normalizedKey] = now;
        eligibleLabels.add(rawLabel);
      }
    }

    if (eligibleLabels.isEmpty) return;

    final isArabic = _settingsController?.language == AppLanguage.arabic;
    final sentence = isArabic
        ? _buildArabicSentence(eligibleLabels)
        : _buildEnglishSentence(eligibleLabels);

    if (sentence.isNotEmpty) {
      final targetLocale = isArabic ? 'ar-EG' : 'en-US';
      if (_lastConfiguredLocale != targetLocale) {
        _lastConfiguredLocale = targetLocale;
        unawaited(tts.setLanguage(targetLocale));
      }
      unawaited(tts.speak(sentence));
    }
  }

  /// Builds a single natural Arabic sentence for objects in the forward zone.
  /// Example (1): "أمامك شخص."
  /// Example (3): "أمامك شخص، كرسي، وسيارة."
  static String _buildArabicSentence(List<String> labels) {
    if (labels.isEmpty) return '';
    final names =
        labels.map((l) => _arabicObjectNames[l.toLowerCase()] ?? l).toList();
    if (names.length == 1) {
      return 'أمامك ${names[0]}.';
    }
    if (names.length == 2) {
      return 'أمامك ${names[0]} و${names[1]}.';
    }
    final allButLast = names.sublist(0, names.length - 1).join('، ');
    return 'أمامك $allButLast، و${names.last}.';
  }

  /// Builds a single natural English sentence for objects in the forward zone.
  /// Example (1): "Person ahead."
  /// Example (3): "Ahead: person, chair, and car."
  static String _buildEnglishSentence(List<String> labels) {
    if (labels.isEmpty) return '';
    if (labels.length == 1) {
      return '${labels[0]} ahead.';
    }
    if (labels.length == 2) {
      return '${labels[0]} and ${labels[1]} ahead.';
    }
    final allButLast = labels.sublist(0, labels.length - 1).join(', ');
    return 'Ahead: $allButLast, and ${labels.last}.';
  }

  @override
  void dispose() {
    _detectionSubscription.cancel();
    super.dispose();
  }
}
