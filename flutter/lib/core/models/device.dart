import 'package:cloud_firestore/cloud_firestore.dart';

enum DeviceConnectionStatus { connected, disconnected }

extension DeviceConnectionStatusValue on DeviceConnectionStatus {
  String get value => name;

  static DeviceConnectionStatus fromValue(String? value) {
    return value == 'connected'
        ? DeviceConnectionStatus.connected
        : DeviceConnectionStatus.disconnected;
  }
}

/// Strongly typed device key matching the schema's
/// `device_key ENUM('smart_glasses','esp32_s3','camera','bluetooth_audio')`.
enum DeviceKey {
  smartGlasses,
  esp32S3,
  camera,
  bluetoothAudio;

  String get value {
    switch (this) {
      case DeviceKey.smartGlasses:
        return 'smart_glasses';
      case DeviceKey.esp32S3:
        return 'esp32_s3';
      case DeviceKey.camera:
        return 'camera';
      case DeviceKey.bluetoothAudio:
        return 'bluetooth_audio';
    }
  }

  static DeviceKey fromValue(String? value) {
    switch (value) {
      case 'smart_glasses':
        return DeviceKey.smartGlasses;
      case 'esp32_s3':
        return DeviceKey.esp32S3;
      case 'camera':
        return DeviceKey.camera;
      case 'bluetooth_audio':
        return DeviceKey.bluetoothAudio;
      default:
        return DeviceKey.smartGlasses;
    }
  }

  String get label {
    switch (this) {
      case DeviceKey.smartGlasses:
        return 'Smart Glasses';
      case DeviceKey.esp32S3:
        return 'ESP32-S3';
      case DeviceKey.camera:
        return 'Camera';
      case DeviceKey.bluetoothAudio:
        return 'Bluetooth Audio';
    }
  }
}

/// Domain model for a paired hardware device.
///
/// Maps to the `devices` table in the backend schema.
///
/// Database mapping (`devices` table):
/// - `device_id`         -> [id]
/// - `user_id`           -> [userId]
/// - `device_name`       -> [deviceName]
/// - `device_key`        -> [deviceKey]
/// - `connection_status` -> [connectionStatus]
/// - `battery_percentage` -> [batteryPercentage]
/// - `last_tested_at`    -> [lastTestedAt]
/// - `updated_at`        -> [updatedAt]
class Device {
  final String deviceId;
  final String userId;
  final String deviceName;
  final DeviceKey deviceKey;
  final DeviceConnectionStatus connectionStatus;
  final int? batteryPercentage;
  final DateTime? lastTestedAt;
  final DateTime? updatedAt;

  const Device({
    required this.deviceId,
    required this.userId,
    required this.deviceName,
    required this.deviceKey,
    this.connectionStatus = DeviceConnectionStatus.disconnected,
    this.batteryPercentage,
    this.lastTestedAt,
    this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['device_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      deviceName: json['device_name'] as String? ?? '',
      deviceKey: DeviceKey.fromValue(json['device_key'] as String?),
      connectionStatus: DeviceConnectionStatusValue.fromValue(
        json['connection_status'] as String?,
      ),
      batteryPercentage: (json['battery_percentage'] as num?)?.toInt(),
      lastTestedAt: json['last_tested_at'] != null
          ? DateTime.tryParse(json['last_tested_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'user_id': userId,
      'device_name': deviceName,
      'device_key': deviceKey.value,
      'connection_status': connectionStatus.value,
      'battery_percentage': batteryPercentage,
      'last_tested_at': lastTestedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Serializes for Firestore `users/{uid}/devices/{deviceId}` document.
  /// Omits `deviceId`, `userId` (path expresses relationship).
  Map<String, dynamic> toFirestore() {
    return {
      'device_name': deviceName,
      'device_key': deviceKey.value,
      'connection_status': connectionStatus.value,
      'battery_percentage': batteryPercentage,
      'last_tested_at':
          lastTestedAt != null ? Timestamp.fromDate(lastTestedAt!) : null,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Deserializes from a Firestore `users/{uid}/devices/{deviceId}` document.
  /// [userId] is required because it is not stored in the document body.
  static Device fromFirestore(DocumentSnapshot doc, {required String userId}) {
    final data = doc.data() as Map<String, dynamic>;
    return Device(
      deviceId: doc.id,
      userId: userId,
      deviceName: data['device_name'] as String? ?? '',
      deviceKey: DeviceKey.fromValue(data['device_key'] as String?),
      connectionStatus: DeviceConnectionStatusValue.fromValue(
        data['connection_status'] as String?,
      ),
      batteryPercentage: (data['battery_percentage'] as num?)?.toInt(),
      lastTestedAt: (data['last_tested_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
