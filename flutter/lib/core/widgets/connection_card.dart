import 'package:flutter/material.dart';
import '../models/system_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A single row in the Devices list: leading icon, device name, and a
/// status pill (icon + text) on the trailing side.
class ConnectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final ConnectionStatus? status;

  const ConnectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.trailingText,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = trailingText ?? status?.label ?? '';
    return Semantics(
      label: '$title, $trailing',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.brightCyan, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (status != null) ...[
              Icon(status!.icon, size: 18, color: status!.color),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              trailing,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: status?.color ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
