import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mock_data.dart';
import '../models/obstacle.dart';
import '../models/system_status.dart';

/// Mock hardware & assistance-session state shared across Home, Devices,
/// and Live Assistance screens.
///
/// All state transitions here are simulated locally with timers; nothing
/// communicates with real hardware, a camera, or a network service.
class DeviceController extends ChangeNotifier {
  ConnectionStatus _glassesStatus = ConnectionStatus.connected;
  ConnectionStatus _cameraStatus = ConnectionStatus.connected;
  ConnectionStatus _audioStatus = ConnectionStatus.connected;
  final bool _aiReady = true;
  int _batteryPercent = MockData.batteryPercent;

  bool _isAssistanceActive = false;
  Obstacle? _latestObstacle = MockData.carAheadNear;

  ConnectionStatus get glassesStatus => _glassesStatus;
  ConnectionStatus get cameraStatus => _cameraStatus;
  ConnectionStatus get audioStatus => _audioStatus;
  bool get aiReady => _aiReady;
  int get batteryPercent => _batteryPercent;

  bool get isAssistanceActive => _isAssistanceActive;
  Obstacle? get latestObstacle => _latestObstacle;

  bool get isSystemReady =>
      _glassesStatus == ConnectionStatus.connected &&
      _cameraStatus == ConnectionStatus.connected &&
      _audioStatus == ConnectionStatus.connected &&
      _aiReady;

  static DeviceController of(BuildContext context, {bool listen = false}) {
    return Provider.of<DeviceController>(context, listen: listen);
  }

  void startAssistance() {
    _isAssistanceActive = true;
    _latestObstacle = MockData.carAheadNear;
    notifyListeners();
  }

  void stopAssistance() {
    _isAssistanceActive = false;
    notifyListeners();
  }

  /// Cycles through a small set of example detections to simulate a
  /// changing environment while assistance is active.
  void cycleMockDetection() {
    final detections = MockData.sampleDetections;
    final currentIndex = _latestObstacle == null
        ? -1
        : detections.indexWhere((o) => o.label == _latestObstacle!.label);
    final nextIndex = (currentIndex + 1) % detections.length;
    _latestObstacle = detections[nextIndex];
    notifyListeners();
  }

  Future<void> reconnectAll() async {
    _glassesStatus = ConnectionStatus.connecting;
    _cameraStatus = ConnectionStatus.connecting;
    _audioStatus = ConnectionStatus.connecting;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _glassesStatus = ConnectionStatus.connected;
    _cameraStatus = ConnectionStatus.connected;
    _audioStatus = ConnectionStatus.connected;
    _batteryPercent = MockData.batteryPercent;
    notifyListeners();
  }

  Future<void> testCamera() async {
    final previous = _cameraStatus;
    _cameraStatus = ConnectionStatus.connecting;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 900));
    _cameraStatus = previous == ConnectionStatus.error
        ? ConnectionStatus.connected
        : previous;
    notifyListeners();
  }

  Future<void> testAudio() async {
    final previous = _audioStatus;
    _audioStatus = ConnectionStatus.connecting;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 900));
    _audioStatus = previous == ConnectionStatus.error
        ? ConnectionStatus.connected
        : previous;
    notifyListeners();
  }
}
