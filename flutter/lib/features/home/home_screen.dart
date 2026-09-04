import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/device_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_logo.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/obstacle_card.dart';
import '../../core/widgets/status_card.dart';
import '../../core/widgets/status_indicator.dart';
import '../../core/models/system_status.dart';

/// Home: the most important screen in the app.
///
/// Shows overall system readiness, a compact per-component status row,
/// the primary "Start Assistance" action, and - when assistance is
/// inactive - the most recent important obstacle, if any. Intentionally
/// kept simple; this is not an analytics dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceController>();
    final isReady = device.isSystemReady;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const EyraLogo(size: 40),
                const SizedBox(width: AppSpacing.sm),
                Text('Eyra', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            StatusCard(
              icon: isReady ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              title: isReady ? context.tr('systemReady') : 'System Not Ready',
              accentColor: isReady ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusIndicator(label: context.tr('glasses'), status: device.glassesStatus),
                  StatusIndicator(label: context.tr('camera'), status: device.cameraStatus),
                  StatusIndicator(label: context.tr('audio'), status: device.audioStatus),
                  StatusIndicator(
                    label: context.tr('ai'),
                    status: device.aiReady ? ConnectionStatus.connected : ConnectionStatus.disconnected,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            EyraPrimaryButton(
              label: context.tr('startAssistance'),
              icon: Icons.play_arrow_rounded,
              onPressed: isReady
                  ? () {
                      device.startAssistance();
                      Navigator.of(context).pushNamed(AppRoutes.liveAssistance);
                    }
                  : null,
            ),
            if (!device.isAssistanceActive && device.latestObstacle != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Last Detected', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              ObstacleCard(obstacle: device.latestObstacle!),
            ],
          ],
        ),
      ),
    );
  }
}
