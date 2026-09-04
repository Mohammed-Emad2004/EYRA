import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/mock_data.dart';
import '../../core/state/device_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/obstacle_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_indicator.dart';

/// Developer-only mock technical monitor.
///
/// Every value shown here is a fixed example constant from [MockData] or
/// the local [DeviceController] mock state - there is no real inference
/// pipeline, model, or hardware link behind this screen.
class DeveloperMonitorScreen extends StatelessWidget {
  const DeveloperMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Monitor')),
      body: SafeArea(
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppColors.warning),
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
              _MetricsGrid(),

              const SectionHeader(title: 'Model'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.model_training_outlined, color: AppColors.brightCyan),
                    const SizedBox(width: AppSpacing.sm),
                    Text(MockData.modelName, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),

              const SectionHeader(title: 'Example Detections'),
              ...MockData.sampleDetections.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ObstacleCard(obstacle: o, showConfidence: true),
                ),
              ),

              const SectionHeader(title: 'System'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusIndicator(label: 'ESP32', status: device.glassesStatus),
                    StatusIndicator(label: 'Camera', status: device.cameraStatus),
                    StatusIndicator(label: 'Audio', status: device.audioStatus),
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
  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('FPS', MockData.fps.toStringAsFixed(1)),
      ('Inference', '${MockData.inferenceMs} ms'),
      ('Network', '${MockData.networkMs} ms'),
      ('Total latency', '${MockData.totalLatencyMs} ms'),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.divider),
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
