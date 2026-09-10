import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../voice_command_service.dart';

/// Local on-device implementation of [VoiceCommandService] using the
/// `speech_to_text` package, which wraps Android's native
/// `SpeechRecognizer` API.
///
/// This service adapts the platform recognizer and emits raw recognized
/// text. It contains no EYRA-specific command logic.
class SpeechRecognitionService implements VoiceCommandService {
  SpeechRecognitionService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  final _resultsController = StreamController<SpeechResult>.broadcast();
  bool _isListening = false;
  bool _resultReceived = false;
  void Function()? _onSessionEnded;

  @override
  bool get isAvailable => _speech.isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  Stream<SpeechResult> get onResults => _resultsController.stream;

  @override
  Future<bool> initialize({void Function()? onSessionEnded}) async {
    _onSessionEnded = onSessionEnded;
    try {
      return await _speech.initialize(
        onError: (error) {
          // Recognition errors (noMatch, timeout, etc.) are not fatal —
          // the service remains available for the next listen attempt.
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            final wasListening = _isListening;
            _isListening = false;
            if (wasListening && !_resultReceived) {
              _onSessionEnded?.call();
            }
          }
        },
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startListening({String? localeId}) async {
    if (!_speech.isAvailable) return;
    _isListening = true;
    _resultReceived = false;
    await _speech.listen(
      onResult: _onResult,
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: false,
        partialResults: false,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  @override
  Future<List<String>> availableLocales() async {
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _isListening = false;
    _speech.cancel();
    _speech.stop();
    _resultsController.close();
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      _resultReceived = true;
      _resultsController.add(SpeechResult(
        text: result.recognizedWords,
        confidence: result.confidence,
      ));
    }
  }
}
