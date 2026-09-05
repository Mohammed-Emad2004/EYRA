import '../models/developer_telemetry.dart';

/// Abstraction boundary for developer/diagnostic telemetry, shown on the
/// Developer Monitor screen.
///
/// [TelemetryController] depends only on this interface, never on a
/// concrete metrics source. Today the only implementation is
/// [MockTelemetryService] (see `mock/mock_telemetry_service.dart`),
/// which returns fixed example values. A future implementation backed
/// by the `developer_telemetry` table (or a real on-device metrics
/// collector) can implement this same interface and be swapped in
/// without changing the Developer Monitor screen.
abstract class TelemetryService {
  Future<DeveloperTelemetry> getLatestTelemetry();
}
