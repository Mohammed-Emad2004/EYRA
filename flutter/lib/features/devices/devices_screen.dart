import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/system_status.dart';
import '../../core/state/device_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/connection_card.dart';
import '../../core/widgets/eyra_secondary_button.dart';
import '../../core/widgets/section_header.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceController>();

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
            Text(context.tr('devices'), style: Theme.of(context).textTheme.displayMedium),
            const SectionHeader(title: 'Hardware'),
            ConnectionCard(
              icon: Icons.visibility_outlined,
              title: context.tr('smartGlasses'),
              status: device.glassesStatus,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConnectionCard(
              icon: Icons.memory_outlined,
              title: 'ESP32-S3',
              status: device.glassesStatus,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConnectionCard(
              icon: Icons.camera_alt_outlined,
              title: context.tr('camera'),
              status: device.cameraStatus,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConnectionCard(
              icon: Icons.headphones_outlined,
              title: context.tr('bluetoothAudio'),
              status: device.audioStatus,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConnectionCard(
              icon: Icons.battery_charging_full_outlined,
              title: context.tr('battery'),
              trailingText: '${device.batteryPercent}%',
            ),
            const SectionHeader(title: 'Actions'),
            EyraSecondaryButton(
              label: context.tr('testCamera'),
              icon: Icons.camera_alt_outlined,
              onPressed: () => device.testCamera(),
            ),
            const SizedBox(height: AppSpacing.sm),
            EyraSecondaryButton(
              label: context.tr('testAudio'),
              icon: Icons.headphones_outlined,
              onPressed: () => device.testAudio(),
            ),
            const SizedBox(height: AppSpacing.sm),
            EyraSecondaryButton(
              label: context.tr('reconnect'),
              icon: Icons.refresh_rounded,
              onPressed: () => device.reconnectAll(),
            ),
          ],
        ),
      ),
    );
  }
}
