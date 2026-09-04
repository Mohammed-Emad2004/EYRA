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

  const ObstacleCard({super.key, required this.obstacle, this.showConfidence = false});

  Color _distanceColor(Distance d) {
    switch (d) {
      case Distance.near:
        return AppColors.error;
      case Distance.medium:
        return AppColors.warning;
      case Distance.far:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceColor = _distanceColor(obstacle.distance);
    final semanticLabel =
        '${obstacle.label}, ${obstacle.direction.label.toLowerCase()}, ${obstacle.distance.label.toLowerCase()}. ${obstacle.spokenSummary}.';

    return Semantics(
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: distanceColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: distanceColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    obstacle.distance.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: distanceColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.explore_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xxs),
                Text(obstacle.direction.label, style: Theme.of(context).textTheme.bodyMedium),
                if (showConfidence) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.verified_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Confidence ${obstacle.confidence.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              obstacle.spokenSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.brightCyan),
            ),
          ],
        ),
      ),
    );
  }
}
