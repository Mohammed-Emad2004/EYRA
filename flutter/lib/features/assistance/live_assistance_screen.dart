import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/obstacle.dart';
import '../../core/state/assistance_controller.dart';
import '../../core/state/camera_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/obstacle_card.dart';

/// Live Assistance: shows the real camera feed with a directional
/// visualization overlay of the most recent detection and a "stop"
/// control.
///
/// The camera feed provides REAL VIDEO INPUT. The obstacle visualization
/// still comes from [AssistanceController] (backed by
/// [MockObstacleDetectionService] today). These are intentionally
/// separate - the camera is real, the detection is mock.
class LiveAssistanceScreen extends StatefulWidget {
  const LiveAssistanceScreen({super.key});

  @override
  State<LiveAssistanceScreen> createState() => _LiveAssistanceScreenState();
}

class _LiveAssistanceScreenState extends State<LiveAssistanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  EyraCameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cameraController = context.read<EyraCameraController>();
      _cameraController!.initialize().then((_) {
        if (!mounted) return;
        if (_cameraController!.isReady) {
          _cameraController!.startImageStream();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    final cam = _cameraController;
    if (cam == null) return;
    await cam.stopImageStream();
    if (mounted) {
      unawaited(AssistanceController.of(context).stopAssistance());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistance = context.watch<AssistanceController>();
    final obstacle = assistance.latestObstacle;
    final cameraState = context.watch<EyraCameraController>();

    return WillPopScope(
      onWillPop: () async {
        await _stop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: SafeArea(
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
                        color: AppColors.cyan
                            .withValues(alpha: 0.4 + _pulseController.value * 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.tr('assistanceActive'),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.cyan),
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
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _CameraWithOverlay(
                    cameraState: cameraState,
                    obstacle: obstacle,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Stacks the real camera preview with the mock obstacle direction
/// overlay on top.
class _CameraWithOverlay extends StatelessWidget {
  final EyraCameraController cameraState;
  final Obstacle? obstacle;

  const _CameraWithOverlay({required this.cameraState, this.obstacle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraLayer(context),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildCameraLayer(BuildContext context) {
    if (cameraState.state == CameraState.ready) {
      final controller = cameraState.flutterController;
      if (controller != null && controller.value.isInitialized) {
        return CameraPreview(controller);
      }
    }

    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cameraState.state == CameraState.error
                  ? Icons.error_outline_rounded
                  : Icons.videocam_off_rounded,
              size: 40,
              color: cameraState.state == CameraState.error
                  ? AppColors.error
                  : AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _cameraStatusLabel(cameraState.state),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _cameraStatusLabel(CameraState state) {
    switch (state) {
      case CameraState.uninitialized:
      case CameraState.initializing:
        return 'Camera initializing...';
      case CameraState.permissionRequired:
        return 'Camera permission required';
      case CameraState.ready:
        return 'Camera ready';
      case CameraState.error:
        return 'Camera unavailable';
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final currentObstacle = obstacle;
    if (currentObstacle == null) {
      return Positioned(
        bottom: AppSpacing.sm,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'No obstacle detected',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: AppSpacing.sm,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.deepNavy.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(currentObstacle.label),
                  color: AppColors.brightCyan, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${currentObstacle.label} - ${currentObstacle.direction.label} - ${currentObstacle.distance.label}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
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
