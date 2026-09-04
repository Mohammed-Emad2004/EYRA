import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_primary_button.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checklist = [
      ('Glasses', Icons.visibility_outlined),
      ('Camera', Icons.camera_alt_outlined),
      ('Audio', Icons.headphones_outlined),
      ('Local AI', Icons.memory_outlined),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.deepNavy, size: 52),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.tr('ready'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Everything is set up and ready to go.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: checklist
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Semantics(
                            label: '${item.$1}, ready',
                            child: Row(
                              children: [
                                Icon(item.$2, color: AppColors.brightCyan, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(item.$1, style: Theme.of(context).textTheme.bodyLarge),
                                ),
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              EyraPrimaryButton(
                label: context.tr('startUsingEyra'),
                onPressed: () {
                  AuthController.of(context).completeOnboarding();
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
