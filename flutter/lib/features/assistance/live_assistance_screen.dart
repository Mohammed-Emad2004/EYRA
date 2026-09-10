import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/obstacle.dart';
import '../../core/state/assistance_controller.dart';
import '../../core/state/camera_controller.dart';
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
      debugPrint(
        '[DIAGNOSTIC] LiveAssistanceScreen: read EyraCameraController(id: ${identityHashCode(_cameraController)}), '
        'CameraService(id: ${identityHashCode(_cameraController?.service)}), '
        'stream(id: ${identityHashCode(_cameraController?.imageStream)})',
      );
      debugPrint('[DIAGNOSTIC] LiveAssistanceScreen: calling initialize()');
      _cameraController!.initialize().then((_) {
        if (!mounted) return;
        debugPrint(
          '[DIAGNOSTIC] LiveAssistanceScreen: initialize() completed. '
          'isReady=${_cameraController!.isReady}, state=${_cameraController!.state}',
        );
        if (_cameraController!.isReady) {
          debugPrint('[DIAGNOSTIC] LiveAssistanceScreen: calling startImageStream()');
          _cameraController!.startImageStream();
        } else {
          debugPrint('[DIAGNOSTIC] LiveAssistanceScreen: NOT calling startImageStream (isReady=false)');
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
    final obstacles = assistance.latestObstacles;
    final obstacle = assistance.latestObstacle;
    final cameraState = context.watch<EyraCameraController>();
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _stop();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
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
                        color: cs.secondary
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
                        ?.copyWith(color: cs.secondary),
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
                    obstacles: obstacles,
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
                    if (obstacles.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.28,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: obstacles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) =>
                              ObstacleCard(obstacle: obstacles[index]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    EyraPrimaryButton(
                      label: context.tr('stopAssistance'),
                      icon: Icons.stop_rounded,
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
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

/// Stacks the real camera preview with the obstacle direction
/// overlay on top.
class _CameraWithOverlay extends StatelessWidget {
  final EyraCameraController cameraState;
  final Obstacle? obstacle;
  final List<Obstacle> obstacles;

  const _CameraWithOverlay({
    required this.cameraState,
    this.obstacle,
    this.obstacles = const [],
  });

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
    final cs = Theme.of(context).colorScheme;
    if (cameraState.state == CameraState.ready) {
      final controller = cameraState.flutterController;
      if (controller != null && controller.value.isInitialized) {
        return CameraPreview(controller);
      }
    }

    return Container(
      color: cs.surfaceContainerHighest,
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
                  ? cs.error
                  : cs.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _cameraStatusLabel(cameraState.state),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;
    final list = obstacles.isNotEmpty
        ? obstacles
        : (obstacle != null ? [obstacle!] : const <Obstacle>[]);

    if (list.isEmpty) {
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
              color: cs.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'No obstacle detected',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.5)),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            alignment: WrapAlignment.center,
            children: list.map((obs) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(obs.label), color: cs.secondary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${obs.label} - ${obs.direction.label} - ${obs.distance.label}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurface),
                  ),
                ],
              );
            }).toList(),
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
