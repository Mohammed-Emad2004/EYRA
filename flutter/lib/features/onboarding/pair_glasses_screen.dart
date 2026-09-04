import 'package:flutter/material.dart';
import '../../app/routes.dart';
import 'widgets/onboarding_connect_step.dart';

class PairGlassesScreen extends StatelessWidget {
  const PairGlassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingConnectStep(
      stepLabel: 'STEP 1 OF 3',
      title: 'Pair Smart Glasses',
      subtitle: 'Searching for your ESP32-S3 smart-glasses module.',
      icon: Icons.visibility_outlined,
      deviceName: 'ESP32-S3',
      continueLabel: 'Continue',
      onContinue: () => Navigator.of(context).pushNamed(AppRoutes.connectAudio),
    );
  }
}
