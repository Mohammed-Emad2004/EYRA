import 'package:flutter/material.dart';
import '../models/system_status.dart';
import '../theme/app_spacing.dart';

/// Small icon + label pill used to show a single connection status.
///
/// Always pairs an icon with text so meaning is never carried by color
/// alone.
class StatusIndicator extends StatelessWidget {
  final String label;
  final ConnectionStatus status;
  final bool dense;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.status,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = '$label ${status.label}';
    return Semantics(
      label: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 18 : 20, color: status.colorOf(context)),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
