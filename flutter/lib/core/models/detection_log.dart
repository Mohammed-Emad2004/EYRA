import 'package:cloud_firestore/cloud_firestore.dart';

import 'obstacle.dart';

enum DangerLevel { low, medium, high }

extension DangerLevelValue on DangerLevel {
  String get value => name;

  static DangerLevel fromValue(String? value) {
    switch (value) {
      case 'medium':
        return DangerLevel.medium;
      case 'high':
        return DangerLevel.high;
      default:
        return DangerLevel.low;
    }
  }
}

/// Domain model for a single obstacle-detection record.
///
/// Maps to the `Detection Logs` table in the backend ERD.
///
/// Database mapping (see ERD `Detection Logs` table):
/// - `log_id`          -> [logId]
/// - `session_id`      -> [sessionId]
/// - `detected_label`  -> [detectedLabel]
/// - `spatial_direction` -> [spatialDirection]
/// - `danger_level`     -> [dangerLevel]
/// - `audio_spoken_text` -> [audioSpokenText]
/// - `created_at`      -> [createdAt]
///
class DetectionLog {
  final String logId;
  final String sessionId;
  final String detectedLabel;
  final SpatialDirection spatialDirection;
  final DangerLevel dangerLevel;
  final String audioSpokenText;
  final DateTime createdAt;

  const DetectionLog({
    required this.logId,
    required this.sessionId,
    required this.detectedLabel,
    required this.spatialDirection,
    required this.dangerLevel,
    required this.audioSpokenText,
    required this.createdAt,
  });

  factory DetectionLog.fromJson(Map<String, dynamic> json) {
    return DetectionLog(
      logId: json['log_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      detectedLabel: json['detected_label'] as String? ?? '',
      spatialDirection: SpatialDirection.values.firstWhere(
        (value) => value.name == json['spatial_direction'],
        orElse: () => SpatialDirection.center,
      ),
      dangerLevel: DangerLevelValue.fromValue(json['danger_level'] as String?),
      audioSpokenText: json['audio_spoken_text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'log_id': logId,
        'session_id': sessionId,
        'detected_label': detectedLabel,
        'spatial_direction': spatialDirection.name,
        'danger_level': dangerLevel.value,
        'audio_spoken_text': audioSpokenText,
        'created_at': createdAt.toIso8601String(),
      };

  /// Converts to the existing [Obstacle] UI model, so screens built
  /// against [Obstacle] (Home, Live Assistance, ObstacleCard) keep
  /// working unchanged.
  Obstacle toObstacle() {
    return Obstacle(
      label: detectedLabel,
      direction: spatialDirection,
      distance: switch (dangerLevel) {
        DangerLevel.low => Distance.far,
        DangerLevel.medium => Distance.medium,
        DangerLevel.high => Distance.near,
      },
    );
  }

  /// Builds a [DetectionLog] from an existing [Obstacle], for use by
  /// mock/local detectors that still think in terms of the simpler
  /// [Obstacle] shape.
  factory DetectionLog.fromObstacle(
    Obstacle obstacle, {
    required String id,
    required String sessionId,
    DateTime? createdAt,
  }) {
    return DetectionLog(
      logId: id,
      sessionId: sessionId,
      detectedLabel: obstacle.label,
      spatialDirection: obstacle.direction,
      dangerLevel: switch (obstacle.distance) {
        Distance.near => DangerLevel.high,
        Distance.medium => DangerLevel.medium,
        Distance.far => DangerLevel.low,
      },
      audioSpokenText: obstacle.spokenSummary,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Serializes for Firestore `.../detection_logs/{logId}` document.
  /// Omits `logId`, `sessionId` (path expresses relationship).
  Map<String, dynamic> toFirestore() {
    return {
      'detected_label': detectedLabel,
      'spatial_direction': spatialDirection.name,
      'danger_level': dangerLevel.value,
      'audio_spoken_text': audioSpokenText,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Deserializes from a Firestore detection_logs document.
  /// `logId` comes from [doc.id]. `sessionId` is not stored in the
  /// document body — pass it via [sessionId] from the parent path.
  factory DetectionLog.fromFirestore(
    DocumentSnapshot doc, {
    required String sessionId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return DetectionLog(
      logId: doc.id,
      sessionId: sessionId,
      detectedLabel: data['detected_label'] as String? ?? '',
      spatialDirection: SpatialDirection.values.firstWhere(
        (value) => value.name == data['spatial_direction'],
        orElse: () => SpatialDirection.center,
      ),
      dangerLevel: DangerLevelValue.fromValue(
        data['danger_level'] as String?,
      ),
      audioSpokenText: data['audio_spoken_text'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
