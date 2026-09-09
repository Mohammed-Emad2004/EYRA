import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/system_status.dart';
import '../services/battery_service.dart';
import '../services/device_communication_service.dart';
import '../services/device_service.dart';
import '../services/mock/mock_battery_service.dart';
import '../services/mock/mock_device_communication_service.dart';
import '../services/mock/mock_device_service.dart';

/// Hardware connection state (glasses, camera, audio, battery) shared
/// across Home and Devices screens.
///
/// This controller is the abstraction boundary those screens depend on.
/// It never talks to real (or mock) hardware directly - it delegates to
/// an injected [DeviceCommunicationService] for the specific
/// connect/test operations the Devices screen performs, an injected
/// [DeviceService] for the schema-shaped device list (`devices` table),
/// and an injected [BatteryService] for real phone battery monitoring.
/// By default those are mock implementations, but real implementations
/// can be passed in instead without changing this class or any screen.
///
/// Note: obstacle-detection/assistance-session state has moved to
/// [AssistanceController] - this controller is now hardware-connection
/// state only.
class DeviceController extends ChangeNotifier {
  DeviceController({
    DeviceCommunicationService? hardware,
    DeviceService? deviceService,
    BatteryService? batteryService,
  })  : _hardware = hardware ?? MockDeviceCommunicationService(),
        _deviceService = deviceService ?? MockDeviceService(),
        _batteryService = batteryService ?? MockBatteryService() {
    _glassesStatus = _hardware.initialGlassesStatus;
    _cameraStatus = _hardware.initialCameraStatus;
    _audioStatus = _hardware.initialAudioStatus;
    unawaited(_initBattery());
    unawaited(_refreshDevices());
  }

  final DeviceCommunicationService _hardware;
  final DeviceService _deviceService;
  final BatteryService _batteryService;
  StreamSubscription<int?>? _batterySubscription;

  late ConnectionStatus _glassesStatus;
  late ConnectionStatus _cameraStatus;
  late ConnectionStatus _audioStatus;
  int? _batteryPercent;

  List<Device> _devices = const [];

  ConnectionStatus get glassesStatus => _glassesStatus;
  ConnectionStatus get cameraStatus => _cameraStatus;
  ConnectionStatus get audioStatus => _audioStatus;

  /// The current phone battery percentage, or `null` if unavailable.
  int? get batteryPercent => _batteryPercent;

  /// Schema-shaped device list (`devices` table), for future use. Not
  /// currently rendered anywhere in the UI, which still displays the
  /// simple glasses/camera/audio rows above.
  List<Device> get devices => _devices;

  bool get isSystemReady =>
      _glassesStatus == ConnectionStatus.connected &&
      _cameraStatus == ConnectionStatus.connected &&
      _audioStatus == ConnectionStatus.connected;

  static DeviceController of(BuildContext context, {bool listen = false}) {
    return Provider.of<DeviceController>(context, listen: listen);
  }

  /// Initializes battery monitoring by reading the current level
  /// and subscribing to level changes.
  Future<void> _initBattery() async {
    // Read the initial battery level.
    final level = await _batteryService.getBatteryLevel();
    _batteryPercent = level;
    notifyListeners();

    // Subscribe to battery level changes.
    _batterySubscription = _batteryService.onBatteryLevelChanged.listen(
      (level) {
        _batteryPercent = level;
        notifyListeners();
      },
      onError: (_) {
        _batteryPercent = null;
        notifyListeners();
      },
    );
  }

  Future<void> _refreshDevices() async {
    _devices = await _deviceService.getDevices();
    notifyListeners();
  }

  Future<void> reconnectAll() async {
    _glassesStatus = ConnectionStatus.connecting;
    _cameraStatus = ConnectionStatus.connecting;
    _audioStatus = ConnectionStatus.connecting;
    notifyListeners();

    final snapshot = await _hardware.reconnectAll();
    _glassesStatus = snapshot.glassesStatus;
    _cameraStatus = snapshot.cameraStatus;
    _audioStatus = snapshot.audioStatus;
    // Battery is now managed by BatteryService, not by hardware reconnect.
    notifyListeners();

    if (_devices.isNotEmpty) {
      await _deviceService.reconnect(_devices.first.deviceId);
      await _refreshDevices();
    }
  }

  Future<void> testCamera() async {
    final previous = _cameraStatus;
    _cameraStatus = ConnectionStatus.connecting;
    notifyListeners();

    _cameraStatus = await _hardware.testCamera(previous);
    notifyListeners();
  }

  Future<void> testAudio() async {
    final previous = _audioStatus;
    _audioStatus = ConnectionStatus.connecting;
    notifyListeners();

    _audioStatus = await _hardware.testAudio(previous);
    notifyListeners();
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    super.dispose();
  }
}
