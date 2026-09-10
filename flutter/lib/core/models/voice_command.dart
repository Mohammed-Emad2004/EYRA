/// Domain model for voice commands recognized by the on-device speech
/// recognizer. The [VoiceCommandService] emits raw speech text; the
/// [VoiceCommandController] classifies it into one of these types.
enum VoiceCommandType {
  startAssistance,
  stopAssistance,
  repeat,
  deviceStatus,
  settings,
  emergency,
  confirmYes,
  confirmNo,
  unrecognized,
}

/// A single voice command after classification by the controller.
class VoiceCommand {
  final VoiceCommandType type;
  final String rawText;
  final double? confidence;
  final String localeId;

  const VoiceCommand({
    required this.type,
    required this.rawText,
    required this.confidence,
    required this.localeId,
  });
}

/// Primary state of the voice-command subsystem, exposed by
/// [VoiceCommandController]. The UI reads this to decide what to render.
enum VoiceCommandState {
  unavailable,
  permissionDenied,
  initializing,
  idle,
  listening,
  processing,
  error,
}
