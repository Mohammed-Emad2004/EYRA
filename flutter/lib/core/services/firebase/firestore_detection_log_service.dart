import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/detection_log.dart';
import '../detection_log_service.dart';

/// Firestore-backed implementation of [DetectionLogService].
///
/// Writes detection events to the
/// `users/{uid}/assistance_sessions/{sessionId}/detection_logs/{logId}`
/// subcollection.
///
/// Persistence policy is deliberately deferred. Not every raw detection
/// event from the AI pipeline should be written to Firestore. The
/// [_shouldPersist] hook is the intended extension point for adding
/// significance filtering, deduplication, or time-based batching without
/// changing the controller architecture.
class FirestoreDetectionLogService implements DetectionLogService {
  FirestoreDetectionLogService({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  /// Determines whether a given detection event should be persisted.
  ///
  /// Override or extend this to implement:
  /// - Confidence thresholds
  /// - Deduplication of consecutive same-label detections
  /// - Time-based batching windows
  /// - Danger-level filtering
  ///
  /// Returning `false` skips the Firestore write entirely.
  bool _shouldPersist(DetectionLog log) {
    // TODO: Implement meaningful-event filtering before production use.
    // This default persists every event — too aggressive for production
    // but correct for initial integration testing.
    return true;
  }

  @override
  Future<void> logDetection({
    required String sessionId,
    required DetectionLog log,
  }) async {
    if (!_shouldPersist(log)) return;

    final colRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('assistance_sessions')
        .doc(sessionId)
        .collection('detection_logs');

    await colRef.add(log.toFirestore());
  }
}
