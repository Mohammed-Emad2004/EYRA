import '../../models/detection_log.dart';
import '../detection_log_service.dart';

/// Local no-op mock implementation of [DetectionLogService].
///
/// Does not persist detection logs. Exists so that
/// [AssistanceController] can be built against the
/// [DetectionLogService] interface during development and testing,
/// and swapped for a real Firestore-backed implementation later
/// without changing the controller.
class MockDetectionLogService implements DetectionLogService {
  @override
  Future<void> logDetection({
    required String sessionId,
    required DetectionLog log,
  }) async {
    // No-op: mock does not persist detection logs
  }
}
