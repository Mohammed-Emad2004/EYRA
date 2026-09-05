/// Domain model for a live-assistance session.
///
/// Maps to the `Assistance Sessions` table in the backend ERD.
///
/// Database mapping (see ERD `Assistance Sessions` table):
/// - `session_id`              -> [id]
/// - `user_id`                 -> [userId]
/// - `camera_device_id`        -> [cameraDeviceId]
/// - `session_mode`            -> [sessionMode]. ENUM values not legible
///   in the ERD - kept as a raw string.
/// - `session_status`          -> [sessionStatus]. Same as above - ENUM
///   values not legible, kept as a raw string.
/// - `ended_at`                -> [endedAt]
/// - `start_latitude`          -> [startLatitude]
/// - `start_longitude`         -> [startLongitude]
/// - `end_latitude`            -> [endLatitude]
/// - `total_frames_processed`  -> [totalFramesProcessed]
/// - `total_detections_count`  -> [totalDetectionsCount]
/// - `avg_fps`                 -> [averageFps]
/// - `avg_latency_ms`          -> [averageLatencyMs]
///
/// AMBIGUOUS SCHEMA FIELDS (see architecture notes for full detail):
/// - [startedAt]: the ERD only shows an `ended_at` column on this table;
///   no clearly visible `started_at`/`created_at` column. Kept here as
///   nullable and populated locally by the mock implementation so the
///   current UI keeps working, pending schema confirmation.
/// - [endLongitude]: the ERD shows `end_latitude` but no corresponding
///   `end_longitude` column, which would be asymmetric with the
///   `start_latitude`/`start_longitude` pair. Kept here as nullable
///   pending confirmation that the column exists.
///
/// Per product requirements, no real GPS is collected; latitude/longitude
/// fields are always mock/placeholder values for now.
class AssistanceSession {
  final String id;
  final String userId;
  final String? cameraDeviceId;
  final String sessionMode;
  final String sessionStatus;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final int totalFramesProcessed;
  final int totalDetectionsCount;
  final double averageFps;
  final double averageLatencyMs;

  const AssistanceSession({
    required this.id,
    required this.userId,
    this.cameraDeviceId,
    this.sessionMode = 'assist',
    this.sessionStatus = 'active',
    this.startedAt,
    this.endedAt,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.totalFramesProcessed = 0,
    this.totalDetectionsCount = 0,
    this.averageFps = 0,
    this.averageLatencyMs = 0,
  });

  AssistanceSession copyWith({
    String? sessionStatus,
    DateTime? endedAt,
    double? endLatitude,
    double? endLongitude,
    int? totalFramesProcessed,
    int? totalDetectionsCount,
    double? averageFps,
    double? averageLatencyMs,
  }) {
    return AssistanceSession(
      id: id,
      userId: userId,
      cameraDeviceId: cameraDeviceId,
      sessionMode: sessionMode,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      totalFramesProcessed: totalFramesProcessed ?? this.totalFramesProcessed,
      totalDetectionsCount: totalDetectionsCount ?? this.totalDetectionsCount,
      averageFps: averageFps ?? this.averageFps,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
    );
  }
}
