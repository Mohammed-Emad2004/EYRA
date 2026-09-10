import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../camera_service.dart';

/// Concrete implementation of [CameraService] backed by the official
/// Flutter `camera` package.
///
/// Selects the rear-facing camera by default. After [initialize], the
/// camera is ready for [CameraPreview]. Image streaming is controlled
/// independently via [startImageStream] / [stopImageStream].
class FlutterCameraService implements CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;
  final _imageStreamController = StreamController<CameraImage>.broadcast();
  int _diagnosticFrameCount = 0;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isStreaming => _isStreaming;

  @override
  CameraController? get controller => _controller;

  @override
  Stream<CameraImage> get imageStream => _imageStreamController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized && _controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NO_CAMERAS',
          'No cameras found on this device.',
        );
      }

      final camera = _selectRearCamera(cameras);
      if (camera == null) {
        throw CameraException(
          'NO_REAR_CAMERA',
          'No rear-facing camera found on this device.',
        );
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      if (!_controller!.value.isInitialized) {
        throw CameraException(
          'INIT_FAILED',
          'Camera controller failed to initialize.',
        );
      }

      _isInitialized = true;
    } on CameraException {
      _isInitialized = false;
      rethrow;
    } catch (e) {
      _isInitialized = false;
      log('FlutterCameraService: unexpected error - $e');
      rethrow;
    }
  }

  @override
  Future<void> startImageStream() async {
    debugPrint(
      '[DIAGNOSTIC] FlutterCameraService.startImageStream() CALLED '
      '(service=${identityHashCode(this)}, controller=${identityHashCode(_controller)}, '
      '_isInitialized=$_isInitialized, _isStreaming=$_isStreaming, '
      'streamController=${identityHashCode(_imageStreamController)})',
    );
    if (_controller == null || !_isInitialized) {
      debugPrint('[DIAGNOSTIC] FlutterCameraService: NOT_INITIALIZED thrown');
      throw CameraException(
        'NOT_INITIALIZED',
        'Camera must be initialized before starting image stream.',
      );
    }

    if (_isStreaming) {
      debugPrint('[DIAGNOSTIC] FlutterCameraService.startImageStream: already streaming, early return');
      return;
    }

    try {
      debugPrint('[DIAGNOSTIC] FlutterCameraService: calling _controller!.startImageStream()');
      await _controller!.startImageStream((CameraImage image) {
        _diagnosticFrameCount++;
        if (_diagnosticFrameCount == 1) {
          debugPrint(
            '[DIAGNOSTIC] FlutterCameraService: FIRST CameraImage received! '
            'width=${image.width}, height=${image.height}, formatGroup=${image.format.group}, '
            'formatRaw=${image.format.raw}, planesCount=${image.planes.length}',
          );
          for (int i = 0; i < image.planes.length; i++) {
            debugPrint(
              '[DIAGNOSTIC]   Plane $i: bytes=${image.planes[i].bytes.length}, '
              'bytesPerRow=${image.planes[i].bytesPerRow}, '
              'bytesPerPixel=${image.planes[i].bytesPerPixel}',
            );
          }
        } else if (_diagnosticFrameCount % 30 == 0) {
          debugPrint(
            '[DIAGNOSTIC] FlutterCameraService: CameraImage frame #$_diagnosticFrameCount received',
          );
        }

        debugPrint(
          '[DIAGNOSTIC] FlutterCameraService: camera callback invoked BEFORE _imageStreamController.add. '
          'frame=#$_diagnosticFrameCount, hasListener=${_imageStreamController.hasListener}, '
          'isClosed=${_imageStreamController.isClosed}',
        );

        if (!_imageStreamController.isClosed) {
          _imageStreamController.add(image);
        }
      });
      _isStreaming = true;
      debugPrint('[DIAGNOSTIC] FlutterCameraService: _controller!.startImageStream() succeeded');
    } on CameraException catch (e) {
      debugPrint('[DIAGNOSTIC] FlutterCameraService: _controller!.startImageStream() failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> stopImageStream() async {
    if (_controller == null || !_isStreaming) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      _isStreaming = false;
    } on CameraException {
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await stopImageStream();
  }

  @override
  Future<void> dispose() async {
    try {
      await stop();
      await _controller?.dispose();
    } catch (e) {
      log('FlutterCameraService: dispose error - $e');
    } finally {
      _controller = null;
      _isInitialized = false;
      _isStreaming = false;
      if (!_imageStreamController.isClosed) {
        await _imageStreamController.close();
      }
    }
  }

  /// Selects the first rear-facing camera from the available cameras list.
  /// Falls back to the first camera if no rear camera is found.
  CameraDescription? _selectRearCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return cameras.isNotEmpty ? cameras.first : null;
  }
}
