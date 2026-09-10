import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/camera_service.dart';
import '../services/local/flutter_camera_service.dart';

/// High-level state of the camera subsystem as seen by the UI.
enum CameraState {
  /// Camera has not been initialized yet.
  uninitialized,

  /// Camera permission is required but has not been granted.
  permissionRequired,

  /// Camera is initializing hardware.
  initializing,

  /// Camera is ready to preview / stream.
  ready,

  /// An error occurred.
  error,
}

/// Application-level camera state controller.
///
/// Manages camera initialization, image streaming, and disposal. Exposes
/// camera state to the UI without leaking Flutter
/// [camera.CameraController] details into build methods.
///
/// The UI never directly initializes or manages the camera controller -
/// all interaction goes through this class.
///
/// Lifecycle:
/// - [initialize] must be called first. After this, the camera is
///   ready for [CameraPreview] and [startImageStream].
/// - [startImageStream] begins delivering frames (idempotent).
/// - [stopImageStream] stops frame delivery (idempotent).
/// - [stopCamera] releases camera hardware. The controller remains
///   reusable - call [initialize] again when needed.
///
/// This controller is app-wide (provided via [MultiProvider]).
/// It is NOT disposed when a screen navigates away.
class EyraCameraController extends ChangeNotifier {
  EyraCameraController({CameraService? service})
      : _service = service ?? FlutterCameraService();

  final CameraService _service;

  /// Diagnostic access to the underlying camera service.
  CameraService get service => _service;

  CameraState _state = CameraState.uninitialized;
  String? _errorMessage;
  bool _isStreaming = false;

  CameraState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isReady => _state == CameraState.ready;
  bool get isStreaming => _isStreaming;

  /// The underlying Flutter [camera.CameraController] for use by
  /// [CameraPreview] widgets. Null until state is [CameraState.ready].
  camera.CameraController? get flutterController => _service.controller;

  /// A stream of raw camera frames. Only produces values when streaming
  /// has been started via [startImageStream]. Designed for future
  /// [LocalYoloDetectionService] consumption.
  Stream<camera.CameraImage> get imageStream => _service.imageStream;

  /// Whether camera hardware has been initialized.
  bool get isInitialized => _service.isInitialized;

  static EyraCameraController of(BuildContext context, {bool listen = false}) {
    return Provider.of<EyraCameraController>(context, listen: listen);
  }

  /// Maps camera package error codes to [CameraState] values where
  /// possible.
  CameraState _stateFromError(camera.CameraException e) {
    final code = e.code.toUpperCase();
    if (code.contains('ACCESSDENIED') ||
        code.contains('ACCESSRESTRICTED') ||
        code.contains('PERMISSION')) {
      return CameraState.permissionRequired;
    }
    return CameraState.error;
  }

  /// Initializes the camera. Safe to call multiple times; subsequent calls
  /// are no-ops if already initialized or currently initializing.
  /// After this completes, the camera is ready for [CameraPreview].
  Future<void> initialize() async {
    debugPrint(
      '[DIAGNOSTIC] EyraCameraController.initialize() CALLED '
      '(controller=${identityHashCode(this)}, service=${identityHashCode(_service)}, '
      'currentState=$_state)',
    );
    if (_state == CameraState.ready || _state == CameraState.initializing) {
      debugPrint(
        '[DIAGNOSTIC] EyraCameraController.initialize: already ready or initializing ($_state), early return',
      );
      return;
    }

    _state = CameraState.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[DIAGNOSTIC] EyraCameraController.initialize: calling _service.initialize()');
      await _service.initialize();
      debugPrint(
        '[DIAGNOSTIC] EyraCameraController.initialize: _service.initialize() finished, isInitialized=${_service.isInitialized}',
      );

      if (_service.isInitialized) {
        _state = CameraState.ready;
      } else {
        _state = CameraState.error;
        _errorMessage = 'Camera failed to initialize.';
      }
    } on camera.CameraException catch (e) {
      _state = _stateFromError(e);
      _errorMessage = e.description;
      debugPrint('[DIAGNOSTIC] EyraCameraController: init CameraException [${e.code}] - ${e.description}');
      log('EyraCameraController: init error [${e.code}] - ${e.description}');
    } catch (e) {
      _state = CameraState.error;
      _errorMessage = 'Unexpected camera error: $e';
      debugPrint('[DIAGNOSTIC] EyraCameraController: unexpected init error - $e');
      log('EyraCameraController: unexpected init error - $e');
    }

    notifyListeners();
  }

  /// Starts the image stream. If the camera is not yet initialized,
  /// [initialize] is called first. Safe to call if already streaming
  /// (idempotent).
  Future<void> startImageStream() async {
    debugPrint(
      '[DIAGNOSTIC] EyraCameraController.startImageStream() CALLED '
      '(controller=${identityHashCode(this)}, service=${identityHashCode(_service)}, '
      'isStreaming=$_isStreaming, state=$_state)',
    );
    if (_state != CameraState.ready) {
      debugPrint('[DIAGNOSTIC] EyraCameraController.startImageStream: state != ready, calling initialize()');
      await initialize();
      if (_state != CameraState.ready) {
        debugPrint('[DIAGNOSTIC] EyraCameraController.startImageStream: still not ready after initialize, aborting');
        return;
      }
    }

    if (_isStreaming) {
      debugPrint('[DIAGNOSTIC] EyraCameraController.startImageStream: already streaming, early return');
      return;
    }

    try {
      debugPrint('[DIAGNOSTIC] EyraCameraController.startImageStream: calling _service.startImageStream()');
      await _service.startImageStream();
      _isStreaming = true;
      debugPrint('[DIAGNOSTIC] EyraCameraController.startImageStream: _service.startImageStream() completed successfully');
      notifyListeners();
    } on camera.CameraException catch (e) {
      debugPrint('[DIAGNOSTIC] EyraCameraController: startImageStream CameraException [${e.code}] - ${e.description}');
      log('EyraCameraController: startImageStream error [${e.code}] - ${e.description}');
    }
  }

  /// Stops the image stream. Safe to call if not streaming (idempotent).
  Future<void> stopImageStream() async {
    try {
      await _service.stopImageStream();
      _isStreaming = false;
      notifyListeners();
    } catch (e) {
      log('EyraCameraController: stopImageStream error - $e');
    }
  }

  /// Stops the camera: releases hardware resources and stops any active
  /// image stream. The controller remains reusable - call [initialize]
  /// again to re-acquire the camera.
  Future<void> stopCamera() async {
    try {
      await _service.stop();
      _isStreaming = false;
      _state = CameraState.uninitialized;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      log('EyraCameraController: stopCamera error - $e');
    }
  }

  /// Synchronous dispose compatible with [ChangeNotifier.dispose].
  ///
  /// Releases camera service resources asynchronously. For reliable
  /// cleanup, call [stopCamera] before this widget is disposed.
  @override
  void dispose() {
    _service.dispose().catchError((e) {
      log('EyraCameraController: dispose cleanup error - $e');
    });
    _state = CameraState.uninitialized;
    _errorMessage = null;
    _isStreaming = false;
    super.dispose();
  }
}
