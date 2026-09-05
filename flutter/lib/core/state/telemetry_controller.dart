import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/detection_log.dart';
import '../models/developer_telemetry.dart';
import '../models/mock_data.dart';
import '../services/mock/mock_telemetry_service.dart';
import '../services/telemetry_service.dart';

/// Developer/diagnostic telemetry state used only by the Developer
/// Monitor screen.
///
/// This controller is the abstraction boundary that screen depends on.
/// It never talks to a metrics source directly - it delegates to an
/// injected [TelemetryService]. By default that is
/// [MockTelemetryService], but a future implementation backed by the
/// `developer_telemetry` table can be passed in instead without
/// changing the Developer Monitor screen.
class TelemetryController extends ChangeNotifier {
  TelemetryController({TelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? MockTelemetryService();

  final TelemetryService _telemetryService;

  DeveloperTelemetry? _telemetry;
  bool _isLoaded = false;

  DeveloperTelemetry? get telemetry => _telemetry;
  bool get isLoaded => _isLoaded;

  /// Fixed example detections for the "Example Detections" section.
  /// Sourced from [MockData] here (a debug-only controller) so the
  /// Developer Monitor screen itself does not need to import mock data
  /// directly.
  List<DetectionLog> get sampleDetections => MockData.sampleDetections
      .asMap()
      .entries
      .map(
        (entry) => DetectionLog.fromObstacle(
          entry.value,
          id: 'sample-log-${entry.key}',
          sessionId: 'sample-session',
        ),
      )
      .toList();

  static TelemetryController of(BuildContext context, {bool listen = false}) {
    return Provider.of<TelemetryController>(context, listen: listen);
  }

  Future<void> load() async {
    _telemetry = await _telemetryService.getLatestTelemetry();
    _isLoaded = true;
    notifyListeners();
  }
}
