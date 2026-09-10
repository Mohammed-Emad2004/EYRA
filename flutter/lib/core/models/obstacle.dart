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
  final List<double>? boundingBox;
  final bool? _isInFrontZone;

  const Obstacle({
    required this.label,
    this.confidence,
    required this.direction,
    required this.distance,
    this.boundingBox,
    bool? isInFrontZone,
  }) : _isInFrontZone = isInFrontZone;

  /// Whether this obstacle is inside or intersects the user's forward
  /// rectangular attention zone. Defaults to true when direction is center.
  bool get isInFrontZone =>
      _isInFrontZone ?? (direction == SpatialDirection.center);

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
