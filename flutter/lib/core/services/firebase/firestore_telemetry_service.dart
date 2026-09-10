import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/developer_telemetry.dart';
import '../telemetry_service.dart';

/// Firestore-backed implementation of [TelemetryService].
///
/// Reads the latest telemetry record from a user's assistance session.
///
/// When [sessionId] is provided, queries only that session's telemetry.
/// When [sessionId] is null, finds the most recent assistance session
/// and reads its latest telemetry record. A Firestore collection group
/// query could be used for true cross-session aggregation in the future.
class FirestoreTelemetryService implements TelemetryService {
  FirestoreTelemetryService({
    required String userId,
    String? sessionId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _sessionId = sessionId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final String? _sessionId;
  final FirebaseFirestore _firestore;

  @override
  Future<DeveloperTelemetry> getLatestTelemetry() async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      return _getFromSession(sessionId);
    }
    return _getAcrossAllSessions();
  }

  Future<DeveloperTelemetry> _getFromSession(String sessionId) async {
    final colRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('assistance_sessions')
        .doc(sessionId)
        .collection('developer_telemetry');

    final snapshot = await colRef
        .orderBy('recorded_at', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return _placeholder(sessionId);
    }

    return DeveloperTelemetry.fromFirestore(
      snapshot.docs.first,
      sessionId: sessionId,
    );
  }

  Future<DeveloperTelemetry> _getAcrossAllSessions() async {
    // Find the most recent session, then read its latest telemetry
    final sessionsSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('assistance_sessions')
        .orderBy('started_at', descending: true)
        .limit(1)
        .get();

    if (sessionsSnapshot.docs.isEmpty) {
      return _placeholder('');
    }

    final sessionId = sessionsSnapshot.docs.first.id;
    return _getFromSession(sessionId);
  }

  DeveloperTelemetry _placeholder(String sessionId) {
    return DeveloperTelemetry(
      telemetryId: '',
      sessionId: sessionId,
      fps: 0,
      inferenceLatencyMs: 0,
      cpuUsagePct: 0,
      ramUsageMb: 0,
      recordedAt: DateTime.now(),
    );
  }
}
