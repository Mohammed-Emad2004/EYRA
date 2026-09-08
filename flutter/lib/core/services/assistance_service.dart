import '../models/assistance_session.dart';

/// Abstraction boundary for assistance-session lifecycle.
///
/// [AssistanceController] depends only on this interface, never on a
/// concrete session store. Today the only implementation is
/// [MockAssistanceService] (see `mock/mock_assistance_service.dart`),
/// which keeps a single in-memory [AssistanceSession]. A future backend
/// implementation, persisting to the `Assistance Sessions` table, can
/// implement this same interface and be swapped in without changing
/// [AssistanceController] or the Live Assistance screen.
abstract class AssistanceService {
  Future<AssistanceSession> startSession({
    required String userId,
  });

  Future<void> stopSession(String sessionId);

  Future<AssistanceSession?> getCurrentSession();
}
