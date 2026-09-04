import 'package:flutter/material.dart';
import '../../app/routes.dart';
import 'widgets/onboarding_connect_step.dart';

class ConnectAudioScreen extends StatelessWidget {
  const ConnectAudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingConnectStep(
      stepLabel: 'STEP 2 OF 3',
      title: 'Connect Audio',
      subtitle: 'Pairing your Bluetooth earphone for spoken alerts.',
      icon: Icons.headphones_outlined,
      deviceName: 'Bluetooth Audio',
      continueLabel: 'Continue',
      onContinue: () => Navigator.of(context).pushNamed(AppRoutes.testCamera),
    );
  }
}
