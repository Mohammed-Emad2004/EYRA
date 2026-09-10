/// A single speech recognition result containing the recognized text
/// and the platform-provided confidence score (if available).
class SpeechResult {
  final String text;
  final double? confidence;

  const SpeechResult({required this.text, this.confidence});
}

/// Abstraction boundary for on-device speech recognition.
///
/// The implementation adapts the platform speech recognizer and emits
/// raw recognized text via [onResults]. It contains no EYRA-specific
/// command classification logic — that lives in the controller layer.
abstract class VoiceCommandService {
  /// Whether the underlying speech recognizer is available on this
  /// device. Returns `false` if no speech recognition engine is installed.
  bool get isAvailable;

  /// Whether the recognizer is currently listening.
  bool get isListening;

  /// A broadcast stream of recognition results. Each event is a
  /// [SpeechResult] containing the final recognized text and the
  /// platform-provided confidence score (which may be `null` if the
  /// platform does not supply one).
  Stream<SpeechResult> get onResults;

  /// Initializes the platform recognizer. Returns `true` if successful.
  /// Returns `false` if the recognizer is not available or permission
  /// was denied.
  ///
  /// [onSessionEnded] is called when a recognition session ends
  /// without producing a result (e.g. timeout, no speech, silence).
  /// It is NOT called when a final result is received.
  Future<bool> initialize({void Function()? onSessionEnded});

  /// Starts a single-command listening session. After one utterance is
  /// recognized, the platform emits a final result and the session ends.
  Future<void> startListening({String? localeId});

  /// Returns the list of speech recognition locale identifiers available
  /// on this device. Each entry is a BCP-47 tag such as `'en-US'` or
  /// `'ar-EG'`. Returns an empty list if the recognizer is not
  /// initialized or locales cannot be queried.
  Future<List<String>> availableLocales();

  /// Stops the current listening session and releases the microphone.
  Future<void> stopListening();

  /// Releases all platform resources. Must be called when the service
  /// is no longer needed (e.g. on controller disposal).
  void dispose();
}
