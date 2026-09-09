import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model for a live-assistance session.
///
/// Maps to the `Assistance Sessions` table in the backend ERD.
///
/// Database mapping (see ERD `Assistance Sessions` table):
enum SessionStatus { active, stopped }

enum AiStatus { ready, processing, error }

extension SessionStatusValue on SessionStatus {
  String get value => name;

  static SessionStatus fromValue(String? value) {
    return value == 'stopped' ? SessionStatus.stopped : SessionStatus.active;
  }
}

extension AiStatusValue on AiStatus {
  String get value => name;

  static AiStatus fromValue(String? value) {
    switch (value) {
      case 'processing':
        return AiStatus.processing;
      case 'error':
        return AiStatus.error;
      default:
        return AiStatus.ready;
    }
  }
}

/// - `session_id`              -> [sessionId]
/// - `user_id`                 -> [userId]
/// - `session_status`          -> [sessionStatus]
/// - `ai_status`               -> [aiStatus]
/// - `started_at`              -> [startedAt]
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
  final String sessionId;
  final String userId;
  final SessionStatus sessionStatus;
  final AiStatus aiStatus;
  final DateTime startedAt;
  final DateTime? endedAt;

  const AssistanceSession({
    required this.sessionId,
    required this.userId,
    this.sessionStatus = SessionStatus.active,
    this.aiStatus = AiStatus.ready,
    required this.startedAt,
    this.endedAt,
  });

  factory AssistanceSession.fromJson(Map<String, dynamic> json) {
    return AssistanceSession(
      sessionId: json['session_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      sessionStatus:
          SessionStatusValue.fromValue(json['session_status'] as String?),
      aiStatus: AiStatusValue.fromValue(json['ai_status'] as String?),
      startedAt: DateTime.parse(json['started_at'].toString()),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.tryParse(json['ended_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'user_id': userId,
        'session_status': sessionStatus.value,
        'ai_status': aiStatus.value,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
      };

  AssistanceSession copyWith({
    SessionStatus? sessionStatus,
    AiStatus? aiStatus,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return AssistanceSession(
      sessionId: sessionId,
      userId: userId,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      aiStatus: aiStatus ?? this.aiStatus,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  /// Serializes for Firestore `users/{uid}/assistance_sessions/{sessionId}`.
  /// Omits `sessionId`, `userId` (path expresses relationship).
  Map<String, dynamic> toFirestore() {
    return {
      'session_status': sessionStatus.value,
      'ai_status': aiStatus.value,
      'started_at': Timestamp.fromDate(startedAt),
      'ended_at': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    };
  }

  /// Deserializes from a Firestore assistance_sessions document.
  /// `sessionId` comes from [doc.id]. `userId` is not stored in
  /// the document body.
  factory AssistanceSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssistanceSession(
      sessionId: doc.id,
      userId: '',
      sessionStatus:
          SessionStatusValue.fromValue(data['session_status'] as String?),
      aiStatus: AiStatusValue.fromValue(data['ai_status'] as String?),
      startedAt: (data['started_at'] as Timestamp).toDate(),
      endedAt: (data['ended_at'] as Timestamp?)?.toDate(),
    );
  }
}
