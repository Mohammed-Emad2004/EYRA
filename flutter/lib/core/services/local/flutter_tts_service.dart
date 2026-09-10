import 'package:flutter_tts/flutter_tts.dart';

import '../text_to_speech_service.dart';

/// Local on-device implementation of [TextToSpeechService] using the
/// `flutter_tts` package, which wraps Android's native `TextToSpeech`
/// engine.
class FlutterTtsService implements TextToSpeechService {
  FlutterTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setCompletionHandler(() {
      _speaking = false;
    });
  }

  final FlutterTts _tts;
  String? _lastSpoken;
  bool _speaking = false;

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<void> speak(String text) async {
    _lastSpoken = text;
    await _tts.stop();
    _speaking = true;
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }

  @override
  Future<void> repeatLast() async {
    if (_lastSpoken != null) {
      await speak(_lastSpoken!);
    }
  }

  @override
  Future<void> setLanguage(String localeId) async {
    String resolved = localeId;
    if (localeId.toLowerCase().startsWith('ar')) {
      resolved = await _resolveArabicLocale();
    }
    await _tts.setLanguage(resolved);
  }

  /// Prefers 'ar-EG' (Egyptian Arabic) and falls back to any available
  /// Arabic locale if 'ar-EG' is not present on the device.
  Future<String> _resolveArabicLocale() async {
    try {
      final dynamic isAvailable = await _tts.isLanguageAvailable('ar-EG');
      if (isAvailable == 1 || isAvailable == true) {
        return 'ar-EG';
      }
      final dynamic langs = await _tts.getLanguages;
      if (langs is List) {
        final stringLangs = langs.map((e) => e.toString()).toList();
        final arEg = stringLangs.firstWhere(
          (l) => l.replaceAll('_', '-').toLowerCase() == 'ar-eg',
          orElse: () => '',
        );
        if (arEg.isNotEmpty) return 'ar-EG';

        final fallback = stringLangs.firstWhere(
          (l) => l.toLowerCase().startsWith('ar'),
          orElse: () => 'ar-EG',
        );
        return fallback;
      }
    } catch (_) {}
    return 'ar-EG';
  }

  @override
  void dispose() {
    _tts.stop();
  }
}
