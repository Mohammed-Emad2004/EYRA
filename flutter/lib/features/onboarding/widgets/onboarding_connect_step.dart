import 'package:flutter/material.dart';
import '../../../core/models/system_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/eyra_primary_button.dart';

/// Shared scaffold for the three onboarding "connect a component" steps
/// (Pair Glasses, Connect Audio, Test Camera).
///
/// Simulates a short local connection delay and then shows a connected
/// state with a continue button. No real hardware, Bluetooth, or camera
/// access ever happens here.
class OnboardingConnectStep extends StatefulWidget {
  final String stepLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final String deviceName;
  final String continueLabel;
  final VoidCallback onContinue;

  const OnboardingConnectStep({
    super.key,
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.deviceName,
    required this.continueLabel,
    required this.onContinue,
  });

  @override
  State<OnboardingConnectStep> createState() => _OnboardingConnectStepState();
}

class _OnboardingConnectStepState extends State<OnboardingConnectStep> {
  ConnectionStatus _status = ConnectionStatus.connecting;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _status = ConnectionStatus.connected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _status == ConnectionStatus.connected;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        widget.stepLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _ConnectVisual(icon: widget.icon, status: _status),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        widget.deviceName,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_status.icon, size: 18, color: _status.colorOf(context)),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(_status.label, style: TextStyle(color: _status.colorOf(context), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      EyraPrimaryButton(
                        label: widget.continueLabel,
                        onPressed: isConnected ? widget.onContinue : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConnectVisual extends StatelessWidget {
  final IconData icon;
  final ConnectionStatus status;

  const _ConnectVisual({required this.icon, required this.status});

  @override
  Widget build(BuildContext context) {
    final connecting = status == ConnectionStatus.connecting;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (connecting)
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(cs.secondary),
                backgroundColor: Theme.of(context).dividerTheme.color ?? cs.outline,
              ),
            ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? cs.outline),
            ),
            child: Icon(icon, size: 46, color: cs.secondary),
          ),
        ],
      ),
    );
  }
}
