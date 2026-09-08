import 'obstacle.dart';

/// Static example data used throughout the app.
///
/// Everything here is hard-coded, local, mock data. No network calls,
/// no AI inference, and no camera/sensor access happen anywhere.
class MockData {
  MockData._();

  static const Obstacle carAheadNear = Obstacle(
    label: 'Car',
    confidence: 0.94,
    direction: SpatialDirection.center,
    distance: Distance.near,
  );

  static const Obstacle personLeftFar = Obstacle(
    label: 'Person',
    confidence: 0.91,
    direction: SpatialDirection.left,
    distance: Distance.far,
  );

  static const Obstacle chairRightMedium = Obstacle(
    label: 'Chair',
    confidence: 0.87,
    direction: SpatialDirection.right,
    distance: Distance.medium,
  );

  static const List<Obstacle> sampleDetections = [
    carAheadNear,
    personLeftFar,
    chairRightMedium,
  ];

  // Mock developer telemetry - fixed example values only.
  static const double fps = 18.4;
  static const int inferenceMs = 72;
  static const int networkMs = 31;
  static const int totalLatencyMs = 145;
  static const String modelName = 'YOLO';

  static const int batteryPercent = 78;
}
