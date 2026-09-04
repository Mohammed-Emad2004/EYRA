import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_logo.dart';
import '../../core/widgets/eyra_primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const EyraLogo(size: 110, withGlow: true),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.tr('welcomeToEyra'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('letsSetUpGlasses'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              EyraPrimaryButton(
                label: context.tr('continueLabel'),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.pairGlasses),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
