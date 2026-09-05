import '../../models/assistance_session.dart';
import '../assistance_service.dart';

/// Local mock implementation of [AssistanceService].
///
/// Keeps a single in-memory [AssistanceSession] and fills its summary
/// fields (frames processed, detections, FPS, latency) with fixed
/// example values on stop. There is no backend persistence involved -
/// this exists purely so [AssistanceController] can be built against
/// the [AssistanceService] interface today, and swapped for a real
/// backend implementation later without touching the controller or the
/// Live Assistance screen.
class MockAssistanceService implements AssistanceService {
  AssistanceSession? _current;
  int _sessionCounter = 0;

  @override
  Future<AssistanceSession> startSession({
    required String userId,
    String? cameraDeviceId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessionCounter++;
    final session = AssistanceSession(
      id: 'mock-session-$_sessionCounter',
      userId: userId,
      cameraDeviceId: cameraDeviceId,
      sessionMode: 'assist',
      sessionStatus: 'active',
      startedAt: DateTime.now(),
      // No real GPS is collected; these are fixed example coordinates.
      startLatitude: 0,
      startLongitude: 0,
    );
    _current = session;
    return session;
  }

  @override
  Future<void> stopSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_current?.id == sessionId) {
      _current = null;
    }
  }

  @override
  Future<AssistanceSession?> getCurrentSession() async {
    return _current;
  }
}
