import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/state/camera_controller.dart';
import '../../core/state/setup_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_primary_button.dart';

/// Onboarding screen that verifies the phone camera is functional.
///
/// Shows the real rear-facing camera preview when available, with clear
/// states for initializing, permission required, ready, and error. The
/// UI layout mirrors the existing OnboardingConnectStep visual identity
/// (step label, title, subtitle, status row, continue button) but uses
/// a real [CameraPreview] instead of a fake connecting animation.
class TestCameraScreen extends StatefulWidget {
  const TestCameraScreen({super.key});

  @override
  State<TestCameraScreen> createState() => _TestCameraScreenState();
}

class _TestCameraScreenState extends State<TestCameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EyraCameraController>().initialize();
      }
    });
  }

  void _onContinue() {
    unawaited(SetupController.of(context).markCameraTested());
    Navigator.of(context).pushNamed(AppRoutes.onboardingReady);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = context.watch<EyraCameraController>();

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
                        'STEP 3 OF 3',
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Test Camera',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Checking that your phone camera feed is ready.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _CameraPreviewArea(cameraState: cameraState),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Camera',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_statusIcon(cameraState.state),
                                size: 18, color: _statusColor(cameraState.state, context)),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              _statusLabel(cameraState.state),
                              style: TextStyle(
                                color: _statusColor(cameraState.state, context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      EyraPrimaryButton(
                        label: 'Continue',
                        onPressed: cameraState.isReady ? _onContinue : null,
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

  String _statusLabel(CameraState state) {
    switch (state) {
      case CameraState.uninitialized:
        return 'Initializing';
      case CameraState.permissionRequired:
        return 'Permission required';
      case CameraState.initializing:
        return 'Connecting';
      case CameraState.ready:
        return 'Connected';
      case CameraState.error:
        return 'Error';
    }
  }

  Color _statusColor(CameraState state, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (state) {
      case CameraState.uninitialized:
      case CameraState.initializing:
        return cs.secondary;
      case CameraState.permissionRequired:
        return AppColors.warningOf(context);
      case CameraState.ready:
        return cs.tertiary;
      case CameraState.error:
        return cs.error;
    }
  }

  IconData _statusIcon(CameraState state) {
    switch (state) {
      case CameraState.uninitialized:
      case CameraState.initializing:
        return Icons.sync_rounded;
      case CameraState.permissionRequired:
        return Icons.vpn_key_rounded;
      case CameraState.ready:
        return Icons.check_circle_rounded;
      case CameraState.error:
        return Icons.error_rounded;
    }
  }
}

/// Displays the camera preview or an appropriate placeholder for each
/// camera state.
class _CameraPreviewArea extends StatelessWidget {
  final EyraCameraController cameraState;

  const _CameraPreviewArea({required this.cameraState});

  @override
  Widget build(BuildContext context) {
    switch (cameraState.state) {
      case CameraState.ready:
        return _buildPreview(context);
      case CameraState.initializing:
      case CameraState.uninitialized:
        return _buildPlaceholder(
          context,
          icon: Icons.sync_rounded,
          label: 'Initializing camera...',
        );
      case CameraState.permissionRequired:
        return _buildPlaceholder(
          context,
          icon: Icons.vpn_key_rounded,
          label: 'Camera permission is required.\nPlease grant camera access in Settings.',
        );
      case CameraState.error:
        return _buildPlaceholder(
          context,
          icon: Icons.error_outline_rounded,
          label: cameraState.errorMessage ?? 'Camera unavailable.',
        );
    }
  }

  Widget _buildPreview(BuildContext context) {
    final controller = cameraState.flutterController;
    final cs = Theme.of(context).colorScheme;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.previewSize == null) {
      return _buildPlaceholder(
        context,
        icon: Icons.sync_rounded,
        label: 'Initializing camera...',
      );
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.secondary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, {required IconData icon, required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (cameraState.state == CameraState.initializing ||
                  cameraState.state == CameraState.uninitialized)
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
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
