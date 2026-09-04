import 'package:flutter/material.dart';
import '../../app/routes.dart';
import 'widgets/onboarding_connect_step.dart';

/// Simulates a camera readiness check. The real device camera is never
/// accessed - this screen only flips a local mock status.
class TestCameraScreen extends StatelessWidget {
  const TestCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingConnectStep(
      stepLabel: 'STEP 3 OF 3',
      title: 'Test Camera',
      subtitle: 'Checking that your smart-glasses camera feed is ready.',
      icon: Icons.camera_alt_outlined,
      deviceName: 'Camera',
      continueLabel: 'Continue',
      onContinue: () => Navigator.of(context).pushNamed(AppRoutes.onboardingReady),
    );
  }
}
