/// Abstraction boundary for text-to-speech output.
///
/// This is the single abstraction for all spoken output in the app —
/// voice-command confirmations, obstacle alerts, status readouts, etc.
/// The implementation wraps the platform TTS engine.
abstract class TextToSpeechService {
  /// Speaks the given [text] aloud. If already speaking, the previous
  /// utterance is stopped first.
  Future<void> speak(String text);

  /// Stops any current utterance.
  Future<void> stop();

  /// Replays the last text that was passed to [speak]. If [speak] has
  /// never been called, this is a no-op.
  Future<void> repeatLast();

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking;

  /// Sets the TTS language. [localeId] should be a BCP-47 tag such as
  /// `'en-US'` or `'ar-SA'`.
  Future<void> setLanguage(String localeId);

  /// Releases platform resources.
  void dispose();
}
