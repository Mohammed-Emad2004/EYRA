import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/obstacle.dart';
import '../../core/state/assistance_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/obstacle_card.dart';

/// Live Assistance: shows a simple directional visualization of the most
/// recent mock detection and a "stop" control. Intentionally not a
/// complex radar or camera dashboard, per product spec.
class LiveAssistanceScreen extends StatefulWidget {
  const LiveAssistanceScreen({super.key});

  @override
  State<LiveAssistanceScreen> createState() => _LiveAssistanceScreenState();
}

class _LiveAssistanceScreenState extends State<LiveAssistanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Detections now stream in from AssistanceController (backed by
    // ObstacleDetectionService), so this screen no longer needs to own
    // a polling Timer itself - that responsibility moved to the mock
    // detection service, matching where a real detector would live.
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _stop() {
    unawaited(AssistanceController.of(context).stopAssistance());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final assistance = context.watch<AssistanceController>();
    final obstacle = assistance.latestObstacle;

    return WillPopScope(
      onWillPop: () async {
        _stop();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) => Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cyan.withOpacity(0.4 + _pulseController.value * 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      context.tr('assistanceActive'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.cyan),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    context.tr('monitoringEnvironment'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: Center(
                    child: obstacle == null
                        ? Text(
                            'No obstacle detected',
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        : _DirectionVisualizer(obstacle: obstacle),
                  ),
                ),
                if (obstacle != null) ...[
                  ObstacleCard(obstacle: obstacle),
                  const SizedBox(height: AppSpacing.lg),
                ],
                EyraPrimaryButton(
                  label: context.tr('stopAssistance'),
                  icon: Icons.stop_rounded,
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textPrimary,
                  onPressed: _stop,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple LEFT / CENTER / RIGHT lane visualization highlighting which
/// lane the current mock obstacle is in.
class _DirectionVisualizer extends StatelessWidget {
  final Obstacle obstacle;

  const _DirectionVisualizer({required this.obstacle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Direction.values.map((d) {
            final isActive = d == obstacle.direction;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: Column(
                  children: [
                    Text(
                      d.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isActive ? AppColors.brightCyan : AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.cyan.withOpacity(0.14) : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isActive ? AppColors.cyan : AppColors.divider,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isActive
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconFor(obstacle.label), color: AppColors.brightCyan, size: 30),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  obstacle.label.toUpperCase(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.brightCyan,
                                      ),
                                ),
                                Text(
                                  obstacle.distance.label,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconFor(String label) {
    switch (label.toLowerCase()) {
      case 'car':
        return Icons.directions_car_filled_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'chair':
        return Icons.chair_alt_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
