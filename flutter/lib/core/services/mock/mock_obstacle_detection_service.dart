import 'dart:async';

import '../../models/detection_log.dart';
import '../../models/mock_data.dart';
import '../obstacle_detection_service.dart';

/// Local mock implementation of [ObstacleDetectionService].
///
/// Cycles through a small, fixed set of example detections from
/// [MockData], pushing one onto [detections] immediately on [start] and
/// then every few seconds while running. There is no camera access,
/// computer-vision inference, or ML model involved - this exists purely
/// so [AssistanceController], Home, and Live Assistance can be built
/// against the [ObstacleDetectionService] interface today, and swapped
/// for a real local YOLO/ONNX-based detector later without touching the
/// controller or any screen.
class MockObstacleDetectionService implements ObstacleDetectionService {
  MockObstacleDetectionService({String sessionId = 'mock-session'}) : _sessionId = sessionId;

  final String _sessionId;
  final _controller = StreamController<DetectionLog>.broadcast();
  Timer? _timer;
  int _index = -1;

  @override
  bool get isReady => true;

  @override
  Stream<DetectionLog> get detections => _controller.stream;

  @override
  void start() {
    _index = -1;
    _emitNext();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _emitNext());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _emitNext() {
    final examples = MockData.sampleDetections;
    _index = (_index + 1) % examples.length;
    final obstacle = examples[_index];
    _controller.add(
      DetectionLog.fromObstacle(
        obstacle,
        id: 'mock-log-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: _sessionId,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Releases the underlying stream controller. Not part of
  /// [ObstacleDetectionService] since real implementations may not need
  /// explicit disposal, but called by [AssistanceController.dispose].
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
