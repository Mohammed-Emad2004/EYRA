import '../models/detection_log.dart';

/// Abstraction boundary for obstacle detection.
///
/// [AssistanceController] depends only on this interface, never on a
/// concrete detector implementation. Today the only implementation is
/// [MockObstacleDetectionService] (see
/// `mock/mock_obstacle_detection_service.dart`), which pushes a fixed
/// set of example [DetectionLog]s on a timer. A future implementation
/// that runs a local YOLO/ONNX model against the live camera feed can
/// implement this same interface and be swapped in at the
/// [AssistanceController] construction site - Home and Live Assistance
/// never need to change.
abstract class ObstacleDetectionService {
  /// Whether the underlying detector (mock or a real on-device model) is
  /// ready to run.
  bool get isReady;

  /// A stream of detections produced while a detection session is
  /// running (see [start]/[stop]). A real implementation would push one
  /// event per inference result; the mock implementation pushes one
  /// example detection at a fixed interval.
  Stream<DetectionLog> get detections;

  /// Starts a detection session.
  void start();

  /// Stops the current detection session.
  void stop();
}
