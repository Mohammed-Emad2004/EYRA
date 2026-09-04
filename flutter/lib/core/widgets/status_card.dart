import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Large status banner used on Home / Live Assistance to communicate the
/// overall system state at a glance (icon + short label + optional
/// subtitle).
class StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;

  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: subtitle == null ? title : '$title. $subtitle',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accentColor.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
