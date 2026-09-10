import '../text_to_speech_service.dart';

/// Mock implementation of [TextToSpeechService] for testing and the
/// unauthenticated provider tree.
///
/// Stores spoken text for [repeatLast] but produces no audio output.
class MockTextToSpeechService implements TextToSpeechService {
  String? _lastSpoken;
  bool _speaking = false;
  final List<String> spokenLog = [];

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<void> speak(String text) async {
    _lastSpoken = text;
    _speaking = true;
    spokenLog.add(text);
    _speaking = false;
  }

  @override
  Future<void> stop() async {
    _speaking = false;
  }

  @override
  Future<void> repeatLast() async {
    if (_lastSpoken != null) {
      await speak(_lastSpoken!);
    }
  }

  @override
  Future<void> setLanguage(String localeId) async {}

  @override
  void dispose() {
    _speaking = false;
  }
}
