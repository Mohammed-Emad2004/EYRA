import '../../models/mock_data.dart';
import '../../models/system_status.dart';
import '../device_communication_service.dart';

/// Local mock implementation of [DeviceCommunicationService].
///
/// Simulates connection latency with simple delays and always succeeds.
/// There is no real Bluetooth, Wi-Fi, or ESP32-S3 communication involved
/// - this exists purely so [DeviceController] can be built and reasoned
/// about against the [DeviceCommunicationService] interface today, and
/// swapped for a real hardware implementation later without touching the
/// controller or any screen.
class MockDeviceCommunicationService implements DeviceCommunicationService {
  @override
  ConnectionStatus get initialGlassesStatus => ConnectionStatus.connected;

  @override
  ConnectionStatus get initialCameraStatus => ConnectionStatus.connected;

  @override
  ConnectionStatus get initialAudioStatus => ConnectionStatus.connected;

  @override
  int get initialBatteryPercent => MockData.batteryPercent;

  @override
  Future<DeviceConnectionSnapshot> reconnectAll() async {
    await Future.delayed(const Duration(seconds: 1));
    return DeviceConnectionSnapshot(
      glassesStatus: ConnectionStatus.connected,
      cameraStatus: ConnectionStatus.connected,
      audioStatus: ConnectionStatus.connected,
      batteryPercent: MockData.batteryPercent,
    );
  }

  @override
  Future<ConnectionStatus> testCamera(ConnectionStatus currentStatus) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return currentStatus == ConnectionStatus.error ? ConnectionStatus.connected : currentStatus;
  }

  @override
  Future<ConnectionStatus> testAudio(ConnectionStatus currentStatus) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return currentStatus == ConnectionStatus.error ? ConnectionStatus.connected : currentStatus;
  }
}
