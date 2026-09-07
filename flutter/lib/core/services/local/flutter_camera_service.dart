import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';

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
    if (_controller == null || !_isInitialized) {
      throw CameraException(
        'NOT_INITIALIZED',
        'Camera must be initialized before starting image stream.',
      );
    }

    if (_isStreaming) return;

    try {
      await _controller!.startImageStream((CameraImage image) {
        if (!_imageStreamController.isClosed) {
          _imageStreamController.add(image);
        }
      });
      _isStreaming = true;
    } on CameraException {
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
