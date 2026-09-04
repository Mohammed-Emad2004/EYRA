import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A single settings row with a label, optional subtitle, and a switch.
///
/// The entire row is tappable and reports its state via semantics so
/// screen readers announce "on"/"off", not just a color change.
class ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: subtitle == null ? label : '$label. $subtitle',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget + 16),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.brightCyan, size: 22),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
