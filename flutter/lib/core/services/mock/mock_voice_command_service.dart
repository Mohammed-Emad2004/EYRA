import 'dart:async';

import '../voice_command_service.dart';

/// Mock implementation of [VoiceCommandService] for testing and the
/// unauthenticated provider tree.
///
/// Does not access any platform speech recognizer. The controller
/// can still exercise its command classification and confirmation
/// logic against commands injected via [emitCommand].
class MockVoiceCommandService implements VoiceCommandService {
  bool _isAvailable = true;
  bool _isListening = false;
  final _resultsController = StreamController<SpeechResult>.broadcast();

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  Stream<SpeechResult> get onResults => _resultsController.stream;

  @override
  Future<bool> initialize({void Function()? onSessionEnded}) async =>
      _isAvailable;

  @override
  Future<void> startListening({String? localeId}) async {
    _isListening = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<List<String>> availableLocales() async => [];

  @override
  void dispose() {
    _isListening = false;
    _resultsController.close();
  }

  /// Injects a raw speech string into the results stream, simulating
  /// what the platform recognizer would produce.
  void emitCommand(String text, {double? confidence}) {
    if (!_resultsController.isClosed) {
      _resultsController.add(SpeechResult(text: text, confidence: confidence));
    }
  }

  /// Controls whether the mock service reports itself as available.
  void setAvailable(bool value) {
    _isAvailable = value;
  }
}
