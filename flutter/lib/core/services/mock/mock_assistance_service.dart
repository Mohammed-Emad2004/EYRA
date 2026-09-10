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
  MockAssistanceService({String userId = 'mock-user'}) : _userId = userId;

  final String _userId;
  AssistanceSession? _current;
  int _sessionCounter = 0;

  @override
  Future<AssistanceSession> startSession() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessionCounter++;
    final session = AssistanceSession(
      sessionId: 'mock-session-$_sessionCounter',
      userId: _userId,
      startedAt: DateTime.now(),
    );
    _current = session;
    return session;
  }

  @override
  Future<void> stopSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_current?.sessionId == sessionId) {
      _current = null;
    }
  }

  @override
  Future<AssistanceSession?> getCurrentSession() async {
    return _current;
  }
}
