/// Relative horizontal direction of a detected obstacle.
enum SpatialDirection { left, center, right }

/// Coarse relative distance bucket of a detected obstacle.
enum Distance { near, medium, far }

extension SpatialDirectionLabel on SpatialDirection {
  String get label {
    switch (this) {
      case SpatialDirection.left:
        return 'LEFT';
      case SpatialDirection.center:
        return 'CENTER';
      case SpatialDirection.right:
        return 'RIGHT';
    }
  }
}

extension DistanceLabel on Distance {
  String get label {
    switch (this) {
      case Distance.near:
        return 'NEAR';
      case Distance.medium:
        return 'MEDIUM';
      case Distance.far:
        return 'FAR';
    }
  }
}

/// A single mock obstacle detection.
///
/// This is a local, static data model only. No real computer-vision
/// inference happens anywhere in this project.
class Obstacle {
  final String label;
  final double? confidence;
  final SpatialDirection direction;
  final Distance distance;

  const Obstacle({
    required this.label,
    this.confidence,
    required this.direction,
    required this.distance,
  });

  /// Short spoken-style summary, e.g. "Car ahead".
  String get spokenSummary {
    switch (direction) {
      case SpatialDirection.center:
        return '$label ahead';
      case SpatialDirection.left:
        return '$label on your left';
      case SpatialDirection.right:
        return '$label on your right';
    }
  }
}
