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
      userId: 'mock-user',
      recordedAt: DateTime.now(),
      ocrLanguage: 'en',
      speechRate: 1.0,
      speechPitch: 1.0,
      speechVolume: 0.8,
      ttsVoiceGender: 'neutral',
      hapticPercentage: 60,
      usagePercentage: 42,
      droppedScans: false,
      networkLatencyMs: MockData.networkMs,
      fps: MockData.fps,
      inferenceMs: MockData.inferenceMs,
      totalLatencyMs: MockData.totalLatencyMs,
      modelName: MockData.modelName,
    );
  }
}
