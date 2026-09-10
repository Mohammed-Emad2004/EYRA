import '../models/detection_log.dart';

/// Abstraction boundary for persisting detection logs.
///
/// [AssistanceController] depends on this interface for writing
/// meaningful detection events to a persistent store. The mock
/// implementation is a no-op. The Firestore implementation writes
/// to the `detection_logs` subcollection.
///
/// Implementations control their own filtering, deduplication, and
/// batching behavior — the controller simply forwards every detection
/// event.
abstract class DetectionLogService {
  /// Persists a detection event for the given [sessionId].
  Future<void> logDetection({
    required String sessionId,
    required DetectionLog log,
  });
}
