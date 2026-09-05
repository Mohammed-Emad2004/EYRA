import 'obstacle.dart';

/// Domain model for a single obstacle-detection record.
///
/// Maps to the `Detection Logs` table in the backend ERD.
///
/// Database mapping (see ERD `Detection Logs` table):
/// - `log_id`          -> [id]
/// - `session_id`      -> [sessionId]
/// - `detection_type`  -> [detectionType]. ENUM values not legible in the
///   ERD - kept as a raw string.
/// - (detected object column) -> [detectedLabel]. AMBIGUOUS: rendered in
///   the ERD as "detected_lade..." - read here as "detected_label",
///   requires confirmation.
/// - `created_at`      -> [createdAt]
///
/// AMBIGUOUS SCHEMA FIELDS (see architecture notes for full detail):
/// The ERD shows two additional `DECIMAL(5,4)` columns on this table
/// (rendered illegibly as roughly "session_ta" and "session_w") that do
/// not clearly correspond to any single named concept. The current
/// product needs a confidence score plus categorical direction/distance
/// (see [Direction], [Distance] in `obstacle.dart`, which this refactor
/// was explicitly told to keep). Rather than guess which illegible ERD
/// column is which, this model:
///   - keeps [confidence] as a product-required field, tentatively
///     associated with one of the two illegible columns;
///   - keeps [direction] and [distance] as the existing categorical
///     enums the UI already renders, since no clearly-named
///     direction/distance column is visible in the ERD at all; and
///   - preserves the two illegible columns verbatim as
///     [rawAmbiguousValueA] / [rawAmbiguousValueB] so no information is
///     silently discarded, pending schema confirmation.
class DetectionLog {
  final String id;
  final String sessionId;
  final String detectionType;
  final String detectedLabel;
  final Direction direction;
  final Distance distance;
  final double? confidence;
  final double? rawAmbiguousValueA;
  final double? rawAmbiguousValueB;
  final DateTime? createdAt;

  const DetectionLog({
    required this.id,
    required this.sessionId,
    required this.detectedLabel,
    required this.direction,
    required this.distance,
    this.detectionType = 'obstacle',
    this.confidence,
    this.rawAmbiguousValueA,
    this.rawAmbiguousValueB,
    this.createdAt,
  });

  /// Converts to the existing [Obstacle] UI model, so screens built
  /// against [Obstacle] (Home, Live Assistance, ObstacleCard) keep
  /// working unchanged.
  Obstacle toObstacle() {
    return Obstacle(
      label: detectedLabel,
      confidence: confidence ?? 0,
      direction: direction,
      distance: distance,
    );
  }

  /// Builds a [DetectionLog] from an existing [Obstacle], for use by
  /// mock/local detectors that still think in terms of the simpler
  /// [Obstacle] shape.
  factory DetectionLog.fromObstacle(
    Obstacle obstacle, {
    required String id,
    required String sessionId,
    DateTime? createdAt,
  }) {
    return DetectionLog(
      id: id,
      sessionId: sessionId,
      detectedLabel: obstacle.label,
      direction: obstacle.direction,
      distance: obstacle.distance,
      confidence: obstacle.confidence,
      createdAt: createdAt,
    );
  }
}
