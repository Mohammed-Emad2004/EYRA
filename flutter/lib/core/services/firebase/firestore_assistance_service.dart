import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/assistance_session.dart';
import '../assistance_service.dart';

/// Firestore-backed implementation of [AssistanceService].
///
/// Manages the `users/{uid}/assistance_sessions/{sessionId}` subcollection.
class FirestoreAssistanceService implements AssistanceService {
  FirestoreAssistanceService({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  CollectionReference get _sessionsCol =>
      _firestore.collection('users').doc(_userId).collection('assistance_sessions');

  @override
  Future<AssistanceSession> startSession() async {
    final docRef = await _sessionsCol.add({
      'session_status': SessionStatus.active.value,
      'ai_status': AiStatus.ready.value,
      'started_at': FieldValue.serverTimestamp(),
      'ended_at': null,
    });
    final doc = await docRef.get();
    return AssistanceSession.fromFirestore(doc);
  }

  @override
  Future<void> stopSession(String sessionId) async {
    final docRef = _sessionsCol.doc(sessionId);
    await docRef.update({
      'session_status': SessionStatus.stopped.value,
      'ended_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<AssistanceSession?> getCurrentSession() async {
    final snapshot = await _sessionsCol
        .where('session_status', isEqualTo: SessionStatus.active.value)
        .orderBy('started_at', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AssistanceSession.fromFirestore(snapshot.docs.first);
  }
}
