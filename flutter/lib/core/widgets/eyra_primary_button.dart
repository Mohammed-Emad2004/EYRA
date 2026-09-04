import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// The primary call-to-action button used across Eyra.
///
/// Always at least [AppSpacing.minTouchTarget] tall, supports a loading
/// state, and an optional leading icon so state is never conveyed by
/// color alone.
class EyraPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const EyraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: SizedBox(
        height: AppSpacing.xxxl - AppSpacing.xs,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.cyan,
            foregroundColor: foregroundColor ?? AppColors.deepNavy,
            disabledBackgroundColor: (backgroundColor ?? AppColors.cyan).withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          child: isLoading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? AppColors.deepNavy,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: foregroundColor ?? AppColors.deepNavy,
                            ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
