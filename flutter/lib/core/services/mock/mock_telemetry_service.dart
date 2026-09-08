import '../../models/developer_telemetry.dart';
import '../../models/mock_data.dart';
import '../telemetry_service.dart';

/// Local mock implementation of [TelemetryService].
///
/// Returns fixed example values - there is no real metrics collector,
/// model, or camera pipeline involved.
class MockTelemetryService implements TelemetryService {
  @override
  Future<DeveloperTelemetry> getLatestTelemetry() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return DeveloperTelemetry(
      telemetryId: 'mock-telemetry',
      sessionId: 'mock-session',
      fps: MockData.fps,
      inferenceLatencyMs: MockData.inferenceMs,
      cpuUsagePct: 42,
      ramUsageMb: 256,
      recordedAt: DateTime.now(),
    );
  }
}
