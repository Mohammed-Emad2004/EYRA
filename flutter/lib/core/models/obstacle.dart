/// Relative horizontal direction of a detected obstacle.
enum Direction { left, center, right }

/// Coarse relative distance bucket of a detected obstacle.
enum Distance { near, medium, far }

extension DirectionLabel on Direction {
  String get label {
    switch (this) {
      case Direction.left:
        return 'LEFT';
      case Direction.center:
        return 'CENTER';
      case Direction.right:
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
  final double confidence;
  final Direction direction;
  final Distance distance;

  const Obstacle({
    required this.label,
    required this.confidence,
    required this.direction,
    required this.distance,
  });

  /// Short spoken-style summary, e.g. "Car ahead".
  String get spokenSummary {
    switch (direction) {
      case Direction.center:
        return '$label ahead';
      case Direction.left:
        return '$label on your left';
      case Direction.right:
        return '$label on your right';
    }
  }
}
