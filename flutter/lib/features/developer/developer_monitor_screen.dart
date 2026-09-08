import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/developer_telemetry.dart';
import '../../core/state/device_controller.dart';
import '../../core/state/telemetry_controller.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/obstacle_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_indicator.dart';

/// Developer-only mock technical monitor.
///
/// Every value shown here comes from [TelemetryController] (backed by
/// [TelemetryService]/`MockTelemetryService`) or the local
/// [DeviceController] mock state - there is no real inference pipeline,
/// model, or hardware link behind this screen.
class DeveloperMonitorScreen extends StatefulWidget {
  const DeveloperMonitorScreen({super.key});

  @override
  State<DeveloperMonitorScreen> createState() => _DeveloperMonitorScreenState();
}

class _DeveloperMonitorScreenState extends State<DeveloperMonitorScreen> {
  @override
  void initState() {
    super.initState();
    final telemetry = TelemetryController.of(context);
    if (!telemetry.isLoaded) {
      telemetry.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceController>();
    final telemetryController = context.watch<TelemetryController>();
    final telemetry = telemetryController.telemetry;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Monitor')),
      body: SafeArea(
        child: telemetry == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: cs.tertiaryContainer),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.science_outlined,
                              color: cs.tertiary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Mock developer data only. No live inference is running.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Performance'),
                    _MetricsGrid(telemetry: telemetry),
                    const SectionHeader(title: 'Model'),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.model_training_outlined,
                              color: cs.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Live metrics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Example Detections'),
                    ...telemetryController.sampleDetections.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ObstacleCard(
                            obstacle: log.toObstacle(), showConfidence: true),
                      ),
                    ),
                    const SectionHeader(title: 'System'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
                      ),
                      child: Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatusIndicator(
                              label: 'ESP32', status: device.glassesStatus),
                          StatusIndicator(
                              label: 'Camera', status: device.cameraStatus),
                          StatusIndicator(
                              label: 'Audio', status: device.audioStatus),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Battery ${device.batteryPercent}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final DeveloperTelemetry telemetry;

  const _MetricsGrid({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('FPS', telemetry.fps.toStringAsFixed(1)),
      ('Inference', '${telemetry.inferenceLatencyMs} ms'),
      ('CPU', '${telemetry.cpuUsagePct.toStringAsFixed(1)}%'),
      ('RAM', '${telemetry.ramUsageMb.toStringAsFixed(1)} MB'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: metrics
          .map(
            (m) => Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Theme.of(context).colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m.$1, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(m.$2, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
