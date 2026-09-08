import 'package:flutter/material.dart';

/// High-level connection status shared by all mock hardware components
/// (glasses, camera, audio).
enum ConnectionStatus { connected, connecting, disconnected, error }

extension ConnectionStatusMeta on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.connected:
        return Icons.check_circle_rounded;
      case ConnectionStatus.connecting:
        return Icons.sync_rounded;
      case ConnectionStatus.disconnected:
        return Icons.radio_button_unchecked_rounded;
      case ConnectionStatus.error:
        return Icons.error_rounded;
    }
  }

  /// Theme-aware color. Pass [context] to resolve from the current theme.
  Color colorOf(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (this) {
      case ConnectionStatus.connected:
        return cs.tertiary;
      case ConnectionStatus.connecting:
        return cs.secondary;
      case ConnectionStatus.disconnected:
        return cs.onSurfaceVariant;
      case ConnectionStatus.error:
        return cs.error;
    }
  }
}

/// Overall system state surfaced on the Home screen.
enum SystemState {
  ready,
  connecting,
  disconnected,
  error,
  assistanceActive,
  noObstacle,
  obstacleDetected,
}

extension SystemStateMeta on SystemState {
  String get label {
    switch (this) {
      case SystemState.ready:
        return 'System Ready';
      case SystemState.connecting:
        return 'Connecting';
      case SystemState.disconnected:
        return 'Disconnected';
      case SystemState.error:
        return 'System Error';
      case SystemState.assistanceActive:
        return 'Assistance Active';
      case SystemState.noObstacle:
        return 'No Obstacle Detected';
      case SystemState.obstacleDetected:
        return 'Obstacle Detected';
    }
  }
}
