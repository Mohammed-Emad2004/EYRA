import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for developer/diagnostic telemetry, shown on the
/// Developer Monitor screen.
///
/// Maps to the `developer_telemetry` table in the SQL schema.
///
/// Database mapping (`developer_telemetry` table):
/// - `telemetry_id`       -> [telemetryId]
/// - `session_id`         -> [sessionId]
/// - `fps`                -> [fps]
/// - `inference_latency_ms` -> [inferenceLatencyMs]
/// - `cpu_usage_pct`      -> [cpuUsagePct]
/// - `ram_usage_mb`       -> [ramUsageMb]
/// - `recorded_at`        -> [recordedAt]
class DeveloperTelemetry {
  final String telemetryId;
  final String sessionId;
  final double fps;
  final int inferenceLatencyMs;
  final double cpuUsagePct;
  final double ramUsageMb;
  final DateTime recordedAt;

  const DeveloperTelemetry({
    required this.telemetryId,
    required this.sessionId,
    required this.fps,
    required this.inferenceLatencyMs,
    required this.cpuUsagePct,
    required this.ramUsageMb,
    required this.recordedAt,
  });

  factory DeveloperTelemetry.fromJson(Map<String, dynamic> json) {
    return DeveloperTelemetry(
      telemetryId: json['telemetry_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      fps: (json['fps'] as num?)?.toDouble() ?? 0,
      inferenceLatencyMs: (json['inference_latency_ms'] as num?)?.toInt() ?? 0,
      cpuUsagePct: (json['cpu_usage_pct'] as num?)?.toDouble() ?? 0,
      ramUsageMb: (json['ram_usage_mb'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.parse(json['recorded_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'telemetry_id': telemetryId,
        'session_id': sessionId,
        'fps': fps,
        'inference_latency_ms': inferenceLatencyMs,
        'cpu_usage_pct': cpuUsagePct,
        'ram_usage_mb': ramUsageMb,
        'recorded_at': recordedAt.toIso8601String(),
      };

  /// Serializes for Firestore `.../developer_telemetry/{telemetryId}`.
  /// Omits `telemetryId`, `sessionId` (path expresses relationship).
  Map<String, dynamic> toFirestore() {
    return {
      'fps': fps,
      'inference_latency_ms': inferenceLatencyMs,
      'cpu_usage_pct': cpuUsagePct,
      'ram_usage_mb': ramUsageMb,
      'recorded_at': Timestamp.fromDate(recordedAt),
    };
  }

  /// Deserializes from a Firestore developer_telemetry document.
  /// `telemetryId` comes from [doc.id]. `sessionId` is not stored in the
  /// document body — pass it via [sessionId] from the parent path.
  factory DeveloperTelemetry.fromFirestore(
    DocumentSnapshot doc, {
    required String sessionId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return DeveloperTelemetry(
      telemetryId: doc.id,
      sessionId: sessionId,
      fps: (data['fps'] as num?)?.toDouble() ?? 0,
      inferenceLatencyMs: (data['inference_latency_ms'] as num?)?.toInt() ?? 0,
      cpuUsagePct: (data['cpu_usage_pct'] as num?)?.toDouble() ?? 0,
      ramUsageMb: (data['ram_usage_mb'] as num?)?.toDouble() ?? 0,
      recordedAt: (data['recorded_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
