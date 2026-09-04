import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A small uppercase section label used to group related settings or
/// content, e.g. "ACCESSIBILITY" above a group of toggles.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.lg),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
