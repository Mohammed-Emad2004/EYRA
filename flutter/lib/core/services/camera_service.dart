import 'dart:async';

import 'package:camera/camera.dart';

/// Abstraction boundary for the phone camera.
///
/// [EyraCameraController] depends only on this interface, never on the
/// Flutter camera package directly. Today the only implementation is
/// [FlutterCameraService], which wraps the official `camera` package.
///
/// Lifecycle:
/// - [initialize] selects the camera and creates the controller.
///   After this, the camera is ready for [CameraPreview].
/// - [startImageStream] / [stopImageStream] control frame delivery
///   independently of the preview.
/// - [stop] stops the image stream. The camera remains initialized.
/// - [dispose] releases all hardware resources.
abstract class CameraService {
  /// Whether the underlying camera hardware has been initialized and
  /// the Flutter [CameraController] is ready for [CameraPreview].
  bool get isInitialized;

  /// Whether the image stream is actively delivering frames.
  bool get isStreaming;

  /// The underlying Flutter [CameraController], available after
  /// [initialize] succeeds. Null before initialization or after
  /// disposal.
  CameraController? get controller;

  /// Initializes the camera hardware (selects rear camera, sets up
  /// resolution). After this completes successfully, the camera is
  /// ready for [CameraPreview].
  Future<void> initialize();

  /// Starts the image stream. Safe to call if already streaming
  /// (idempotent).
  Future<void> startImageStream();

  /// Stops the image stream. Safe to call if not streaming
  /// (idempotent).
  Future<void> stopImageStream();

  /// Stops the image stream. The camera remains initialized and
  /// ready for preview or streaming again.
  Future<void> stop();

  /// Releases all camera resources. The service can be re-initialized
  /// after disposal.
  Future<void> dispose();

  /// A stream of [CameraImage] frames from the camera. Only produces
  /// values when [startImageStream] has been called.
  ///
  /// Designed so a future [LocalYoloDetectionService] can subscribe to
  /// frames without rewriting the camera or UI architecture.
  Stream<CameraImage> get imageStream;
}
