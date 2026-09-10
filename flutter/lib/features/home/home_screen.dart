import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/assistance_controller.dart';
import '../../core/state/device_controller.dart';
import '../../core/state/voice_command_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_logo.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/obstacle_card.dart';
import '../../core/widgets/status_card.dart';
import '../../core/widgets/status_indicator.dart';
import '../../core/models/system_status.dart';
import '../voice/voice_command_button.dart';

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
    final assistance = context.watch<AssistanceController>();
    final vc = context.watch<VoiceCommandController>();
    final isReady = device.isSystemReady && assistance.isDetectorReady;
    final cs = Theme.of(context).colorScheme;

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
              icon: isReady
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              title: isReady ? context.tr('systemReady') : 'System Not Ready',
              accentColor: isReady ? cs.tertiary : AppColors.warningOf(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
              ),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusIndicator(
                      label: context.tr('glasses'),
                      status: device.glassesStatus),
                  StatusIndicator(
                      label: context.tr('camera'), status: device.cameraStatus),
                  StatusIndicator(
                      label: context.tr('audio'), status: device.audioStatus),
                  StatusIndicator(
                    label: context.tr('ai'),
                    status: assistance.isDetectorReady
                        ? ConnectionStatus.connected
                        : ConnectionStatus.disconnected,
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
                      debugPrint('[DIAGNOSTIC] HomeScreen: Start Assistance button pressed');
                      unawaited(assistance.startAssistance());
                      Navigator.of(context).pushNamed(AppRoutes.liveAssistance);
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const VoiceCommandButton(),
            Text(
              '[DEV] Voice Ready: ${vc.voiceReadyMode ? "ON" : "OFF"} '
              '| State: ${vc.state.name} '
              '| Locale: ${vc.localeId}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
            if (vc.lastCommand != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '[DEV] "${vc.lastCommand!.rawText}" '
                '(confidence: ${vc.lastCommand!.confidence ?? "n/a"}, '
                'locale: ${vc.lastCommand!.localeId}, '
                'type: ${vc.lastCommand!.type.name})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
              ),
            ],
            if (!assistance.isAssistanceActive &&
                assistance.latestObstacle != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Last Detected',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              ObstacleCard(obstacle: assistance.latestObstacle!),
            ],
          ],
        ),
      ),
    );
  }
}
