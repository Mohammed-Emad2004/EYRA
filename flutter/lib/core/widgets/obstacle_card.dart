import 'package:flutter/material.dart';
import '../models/obstacle.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Displays a single obstacle detection: label, direction, distance,
/// and a short spoken-style summary such as "Car ahead".
///
/// Distance is additionally shown via a colored badge label (text, not
/// color alone) so it stays accessible.
class ObstacleCard extends StatelessWidget {
  final Obstacle obstacle;
  final bool showConfidence;

  const ObstacleCard(
      {super.key, required this.obstacle, this.showConfidence = false});

  Color _distanceColor(Distance d, BuildContext context) {
    switch (d) {
      case Distance.near:
        return AppColors.errorOf(context);
      case Distance.medium:
        return AppColors.warningOf(context);
      case Distance.far:
        return AppColors.successOf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final distanceColor = _distanceColor(obstacle.distance, context);
    final semanticLabel =
        '${obstacle.label}, ${obstacle.direction.label.toLowerCase()}, ${obstacle.distance.label.toLowerCase()}. ${obstacle.spokenSummary}.';

    return Semantics(
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    obstacle.label.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: distanceColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: distanceColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    obstacle.distance.label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: distanceColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.explore_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xxs),
                Text(obstacle.direction.label,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (showConfidence) ...[
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.verified_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Confidence ${(obstacle.confidence ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              obstacle.spokenSummary,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
