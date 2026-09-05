import '../models/system_status.dart';

/// A snapshot of hardware connection state returned after a reconnect
/// attempt.
class DeviceConnectionSnapshot {
  final ConnectionStatus glassesStatus;
  final ConnectionStatus cameraStatus;
  final ConnectionStatus audioStatus;
  final int batteryPercent;

  const DeviceConnectionSnapshot({
    required this.glassesStatus,
    required this.cameraStatus,
    required this.audioStatus,
    required this.batteryPercent,
  });
}

/// Abstraction boundary for talking to the physical smart-glasses
/// hardware (glasses, camera, audio, battery).
///
/// [DeviceController] depends only on this interface, never on Bluetooth,
/// Wi-Fi, or any concrete transport directly. Today the only
/// implementation is [MockDeviceCommunicationService] (see
/// `mock/mock_device_communication_service.dart`), which simulates
/// connection latency locally. A future implementation that speaks to a
/// real ESP32-S3 over Wi-Fi can implement this same interface and be
/// swapped in at the [DeviceController] construction site - no screen
/// needs to change.
abstract class DeviceCommunicationService {
  /// Connection status to report immediately when the app starts, before
  /// any explicit reconnect/test call has been made.
  ConnectionStatus get initialGlassesStatus;
  ConnectionStatus get initialCameraStatus;
  ConnectionStatus get initialAudioStatus;
  int get initialBatteryPercent;

  /// Attempts to (re)connect all hardware components and returns the
  /// resulting state once the attempt completes.
  Future<DeviceConnectionSnapshot> reconnectAll();

  /// Runs a camera self-test, given its current status, and returns the
  /// resulting status.
  Future<ConnectionStatus> testCamera(ConnectionStatus currentStatus);

  /// Runs an audio self-test, given its current status, and returns the
  /// resulting status.
  Future<ConnectionStatus> testAudio(ConnectionStatus currentStatus);
}
