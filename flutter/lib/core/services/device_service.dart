import '../models/device.dart';

/// Abstraction boundary for the user's paired hardware devices, shaped
/// after the backend `devices` table.
///
/// This sits alongside the lower-level [DeviceCommunicationService]
/// (which the current Devices screen's connect/test operations already
/// use): [DeviceService] is the schema-shaped, list-of-devices view a
/// future "manage devices" experience (or a real backend) would use,
/// while [DeviceCommunicationService] remains the operational boundary
/// for the specific glasses/camera/audio connect+test flows the current
/// UI performs. Both are mock-backed today and can be replaced by real
/// implementations independently.
abstract class DeviceService {
  Future<List<Device>> getDevices();
  Future<Device?> getDevice(String deviceId);
  Future<void> reconnect(String deviceId);
}
