import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_logo.dart';
import '../../core/widgets/section_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const technologies = [
      ('Flutter', Icons.flutter_dash_rounded),
      ('ESP32-S3', Icons.memory_outlined),
      ('Computer Vision', Icons.visibility_outlined),
      ('On-device AI', Icons.psychology_outlined),
      ('Text-to-Speech', Icons.record_voice_over_outlined),
    ];

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about'))),
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
              const Center(child: EyraLogo(size: 96, withGlow: true)),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(context.tr('appName'), style: Theme.of(context).textTheme.displayMedium),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Center(
                child: Text(
                  context.tr('assistiveVision'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.secondary),
                ),
              ),
              const SectionHeader(title: 'About Eyra'),
              Text(
                'Eyra is a local-AI smart-glasses system designed to help '
                'visually impaired users identify nearby obstacles, '
                'understand their direction, and estimate relative distance.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SectionHeader(title: 'Technology'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
                ),
                child: Column(
                  children: technologies
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              Icon(t.$2, color: cs.secondary, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Text(t.$1, style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
