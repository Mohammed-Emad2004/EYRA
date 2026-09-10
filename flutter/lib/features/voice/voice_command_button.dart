import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/voice_command.dart';
import '../../core/state/voice_command_controller.dart';

/// A floating action button that controls Voice Ready Mode.
///
/// When Voice Ready Mode is ON, tapping the button turns it OFF.
/// When Voice Ready Mode is OFF, tapping the button turns it ON.
/// The button's appearance reflects the current [VoiceCommandState]
/// and Voice Ready Mode status.
class VoiceCommandButton extends StatelessWidget {
  const VoiceCommandButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vc = context.watch<VoiceCommandController>();
    final cs = Theme.of(context).colorScheme;
    final ready = vc.voiceReadyMode;

    if (!vc.isAvailable && vc.state != VoiceCommandState.unavailable) {
      return const SizedBox.shrink();
    }

    final (icon, label, color, enabled) = switch (vc.state) {
      VoiceCommandState.unavailable => (
          Icons.mic_off_rounded,
          'Voice unavailable',
          cs.error,
          false,
        ),
      VoiceCommandState.permissionDenied => (
          Icons.mic_off_rounded,
          'Mic permission required',
          cs.error,
          false,
        ),
      VoiceCommandState.initializing => (
          Icons.mic_none_rounded,
          'Initializing...',
          cs.outline,
          false,
        ),
      VoiceCommandState.listening when ready => (
          Icons.mic_rounded,
          'Voice Ready: ON',
          cs.primary,
          true,
        ),
      VoiceCommandState.listening => (
          Icons.mic_rounded,
          'Listening...',
          cs.primary,
          true,
        ),
      VoiceCommandState.processing => (
          Icons.hourglass_top_rounded,
          'Processing...',
          cs.tertiary,
          false,
        ),
      VoiceCommandState.error => (
          Icons.error_outline_rounded,
          vc.error ?? 'Error',
          cs.error,
          true,
        ),
      VoiceCommandState.idle when ready => (
          Icons.mic_rounded,
          'Voice Ready: ON',
          cs.tertiary,
          true,
        ),
      VoiceCommandState.idle => (
          Icons.mic_rounded,
          'Voice Ready: OFF',
          cs.outline,
          true,
        ),
    };

    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      focused: vc.state == VoiceCommandState.listening,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vc.isAwaitingConfirmation)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Say "yes" or "no"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.tertiary,
                    ),
              ),
            ),
          FloatingActionButton(
            onPressed: enabled
                ? () async {
                    if (vc.voiceReadyMode) {
                      await vc.stopVoiceReadyMode();
                    } else {
                      await vc.startVoiceReadyMode();
                    }
                  }
                : null,
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
