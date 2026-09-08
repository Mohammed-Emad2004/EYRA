import '../../models/device.dart';
import '../../models/mock_data.dart';
import '../device_service.dart';

/// Local mock implementation of [DeviceService].
///
/// Represents the single Eyra smart-glasses unit (ESP32-S3) as one
/// [Device] with fixed example values. There is no real Wi-Fi/USB
/// enumeration involved - this exists purely so the app can be built
/// against the [DeviceService] interface today, and swapped for a real
/// backend-backed implementation later without changing any screen.
class MockDeviceService implements DeviceService {
  static const _mockDeviceId = 'mock-device-esp32-s3';
  static const _mockUserId = 'mock-user';

  Device _buildMockDevice() {
    return Device(
      deviceId: _mockDeviceId,
      userId: _mockUserId,
      deviceName: 'Eyra Smart Glasses',
      deviceKey: DeviceKey.esp32S3,
      batteryPercentage: MockData.batteryPercent,
      lastTestedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      connectionStatus: DeviceConnectionStatus.connected,
    );
  }

  @override
  Future<List<Device>> getDevices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [_buildMockDevice()];
  }

  @override
  Future<Device?> getDevice(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return deviceId == _mockDeviceId ? _buildMockDevice() : null;
  }

  @override
  Future<void> reconnect(String deviceId) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
