import 'system_status.dart';

/// Domain model for a paired hardware device (e.g. the Eyra smart
/// glasses / ESP32-S3 unit).
///
/// Maps to the `devices` table in the backend ERD.
///
/// Database mapping (see ERD `devices` table):
/// - `device_id`            -> [id]
/// - `user_id`              -> [userId]
/// - `device_name`          -> [name]
/// - `device_type`          -> [deviceType]. ENUM values not legible in
///   the ERD - kept as a raw string rather than a typed Dart enum.
/// - `connection_protocol`  -> [connectionProtocol]. Same as above -
///   ENUM values not legible, kept as a raw string.
/// - `serial_number`        -> [serialNumber]
/// - `mac_address`          -> [macAddress]
/// - `ip_address`           -> [ipAddress]
/// - `stream_endpoint_url`  -> [streamEndpointUrl]
/// - `usb_vendor_id`        -> [usbVendorId]
/// - `firmware_version`     -> [firmwareVersion]
/// - `battery_level`        -> [batteryLevel]
/// - `is_charging`          -> [isCharging]
/// - `signal_strength_rssi` -> [signalStrengthRssi]
/// - `last_heartbeat_at`    -> [lastHeartbeatAt]
/// - `created_at`           -> [createdAt]
///
/// [connectionStatus] is NOT a database column - it is a UI-facing
/// convenience derived by the service/mock layer from heartbeat
/// freshness/RSSI, so screens can keep using the existing
/// [ConnectionStatus] enum without reaching into raw telemetry fields.
class Device {
  final String id;
  final String userId;
  final String name;
  final String deviceType;
  final String connectionProtocol;
  final String? serialNumber;
  final String? macAddress;
  final String? ipAddress;
  final String? streamEndpointUrl;
  final String? usbVendorId;
  final String? firmwareVersion;
  final int? batteryLevel;
  final bool isCharging;
  final int? signalStrengthRssi;
  final DateTime? lastHeartbeatAt;
  final DateTime? createdAt;
  final ConnectionStatus connectionStatus;

  const Device({
    required this.id,
    required this.userId,
    required this.name,
    required this.deviceType,
    required this.connectionProtocol,
    this.serialNumber,
    this.macAddress,
    this.ipAddress,
    this.streamEndpointUrl,
    this.usbVendorId,
    this.firmwareVersion,
    this.batteryLevel,
    this.isCharging = false,
    this.signalStrengthRssi,
    this.lastHeartbeatAt,
    this.createdAt,
    this.connectionStatus = ConnectionStatus.disconnected,
  });
}
