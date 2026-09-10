import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_settings.dart';
import '../models/voice_command.dart';
import '../services/text_to_speech_service.dart';
import '../services/voice_command_service.dart';

/// Controller for the voice-command subsystem.
///
/// This is a pure Dart [ChangeNotifier] with zero Flutter UI dependencies.
/// It owns the [VoiceCommandService] and [TextToSpeechService] lifecycles,
/// classifies raw speech text into [VoiceCommand] events, manages the
/// emergency confirmation state machine, and emits classified commands
/// on [onCommand] for the router widget to dispatch.
///
/// Voice Ready Mode enables hands-free operation by automatically
/// starting a new recognition session after each command is processed
/// and TTS feedback completes.
class VoiceCommandController extends ChangeNotifier {
  VoiceCommandController({
    required VoiceCommandService voiceCommandService,
    required TextToSpeechService textToSpeechService,
  })  : _voiceService = voiceCommandService,
        _ttsService = textToSpeechService;

  final VoiceCommandService _voiceService;
  final TextToSpeechService _ttsService;

  VoiceCommandState _state = VoiceCommandState.initializing;
  VoiceCommand? _lastCommand;
  String? _error;
  String _localeId = 'en-US';
  VoiceCommandType _pendingConfirmation = VoiceCommandType.unrecognized;
  StreamSubscription<SpeechResult>? _speechSubscription;
  AppLanguage _appLanguage = AppLanguage.english;

  // ── Voice Ready Mode ─────────────────────────────────────────
  bool _voiceReadyMode = false;
  Timer? _restartTimer;

  final _commandController = StreamController<VoiceCommand>.broadcast();

  // ── Getters ────────────────────────────────────────────────────

  VoiceCommandState get state => _state;
  VoiceCommand? get lastCommand => _lastCommand;
  String? get error => _error;
  bool get isAvailable => _voiceService.isAvailable;
  bool get isAwaitingConfirmation =>
      _pendingConfirmation != VoiceCommandType.unrecognized;
  String get localeId => _localeId;

  /// Whether Voice Ready Mode is currently enabled. When true, a new
  /// recognition session starts automatically after each command is
  /// processed and TTS feedback completes.
  bool get voiceReadyMode => _voiceReadyMode;

  /// The current application language.
  AppLanguage get appLanguage => _appLanguage;

  /// Expose TTS for the router to call speak/repeat without the
  /// controller needing to know about specific output actions.
  TextToSpeechService get textToSpeechService => _ttsService;

  /// Classified commands. The router widget subscribes to this.
  Stream<VoiceCommand> get onCommand => _commandController.stream;

  // ── Public methods ─────────────────────────────────────────────

  /// Updates the application language. This reconfigures the speech
  /// recognition locale, TTS language, and command classifier to match.
  Future<void> setAppLanguage(AppLanguage language) async {
    _appLanguage = language;
    _localeId = await _resolveSpeechLocale(language);
    await _ttsService.setLanguage(_localeId);
    notifyListeners();
  }

  /// Initializes the speech service. Returns `false` if unavailable.
  Future<bool> initialize() async {
    _state = VoiceCommandState.initializing;
    notifyListeners();

    final available = await _voiceService.initialize(
      onSessionEnded: _onSessionEnded,
    );
    if (!available) {
      _state = VoiceCommandState.unavailable;
      _error = 'Speech recognition not available on this device';
      notifyListeners();
      return false;
    }

    // Resolve speech locale for the current app language.
    _localeId = await _resolveSpeechLocale(_appLanguage);
    await _ttsService.setLanguage(_localeId);

    _speechSubscription = _voiceService.onResults.listen(
      _onRawSpeechResult,
      onError: (Object e) {
        _state = VoiceCommandState.error;
        _error = 'Recognition error: $e';
        notifyListeners();
        if (_voiceReadyMode) {
          _scheduleNextSession();
        }
      },
    );

    _state = VoiceCommandState.idle;
    _error = null;
    notifyListeners();
    return true;
  }

  /// Activates Voice Ready Mode. A recognition session starts
  /// immediately and a new session is started automatically after each
  /// command is processed and TTS feedback completes.
  Future<void> startVoiceReadyMode() async {
    if (_voiceReadyMode) return;
    _voiceReadyMode = true;
    _error = null;
    notifyListeners();
    await startListening();
  }

  /// Deactivates Voice Ready Mode. Cancels any pending restart and
  /// stops the current recognition session.
  Future<void> stopVoiceReadyMode() async {
    if (!_voiceReadyMode) return;
    _voiceReadyMode = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    await _voiceService.stopListening();
    if (_state == VoiceCommandState.listening ||
        _state == VoiceCommandState.processing) {
      _state = VoiceCommandState.idle;
      notifyListeners();
    }
  }

  /// Activates single-command listening. After one utterance is
  /// recognized the state transitions to [VoiceCommandState.processing],
  /// the command is classified, emitted on [onCommand], and the state
  /// returns to [VoiceCommandState.idle].
  Future<void> startListening() async {
    if (_state == VoiceCommandState.listening) return;

    _error = null;

    if (!_voiceService.isAvailable) {
      _state = VoiceCommandState.unavailable;
      _error = 'Speech recognition not available';
      notifyListeners();
      return;
    }

    try {
      await _voiceService.startListening(localeId: _localeId);
      _state = VoiceCommandState.listening;
      notifyListeners();
    } catch (e) {
      _state = VoiceCommandState.error;
      _error = 'Failed to start listening: $e';
      notifyListeners();
    }
  }

  /// Stops only the current recognition session. Does NOT disable
  /// Voice Ready Mode — the next session will be scheduled if
  /// Voice Ready Mode is still enabled.
  Future<void> stopListening() async {
    await _voiceService.stopListening();
    if (_state == VoiceCommandState.listening ||
        _state == VoiceCommandState.processing) {
      _state = VoiceCommandState.idle;
      notifyListeners();
    }
  }

  /// Cancels any pending emergency confirmation.
  void cancelConfirmation() {
    if (_pendingConfirmation != VoiceCommandType.unrecognized) {
      _pendingConfirmation = VoiceCommandType.unrecognized;
      if (_appLanguage == AppLanguage.arabic) {
        _ttsService.speak('تم الإلغاء');
      } else {
        _ttsService.speak('Cancelled');
      }
      notifyListeners();
    }
  }

  // ── Speech locale resolution ───────────────────────────────────

  /// Resolves the best speech recognition locale for the given app
  /// language by querying available device locales.
  Future<String> _resolveSpeechLocale(AppLanguage language) async {
    final prefix = language == AppLanguage.arabic ? 'ar' : 'en';
    final available = await _voiceService.availableLocales();
    if (available.isEmpty) {
      return language == AppLanguage.arabic ? 'ar-EG' : 'en-US';
    }
    if (language == AppLanguage.arabic) {
      final arEg = available.firstWhere(
        (l) => l.replaceAll('_', '-').toLowerCase() == 'ar-eg',
        orElse: () => '',
      );
      if (arEg.isNotEmpty) return arEg;
    }
    // Prefer an exact regional match, then any locale with the prefix.
    final exact =
        available.where((l) => l.toLowerCase().startsWith(prefix)).toList();
    if (exact.isNotEmpty) {
      return exact.first;
    }
    return language == AppLanguage.arabic ? 'ar-EG' : 'en-US';
  }

  // ── Arabic text normalization ──────────────────────────────────

  /// Normalizes Arabic text for more robust command matching.
  /// Handles common speech-recognition variations without changing
  /// command meaning.
  static String _normalizeArabic(String text) {
    var result = text.trim();
    // Normalize alef variants: أ إ آ → ا
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Normalize ta marbuta: ة → ه
    result = result.replaceAll('ة', 'ه');
    // Normalize ta tremel: ؤ → و
    result = result.replaceAll('ؤ', 'و');
    // Normalize yeh with hamza: ئ → ي
    result = result.replaceAll('ئ', 'ي');
    // Remove diacritics/tashkeel (fatha, damma, kasra, sukun, etc.)
    result = result.replaceAll(
        RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC'
            r'\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]'),
        '');
    // Normalize multiple whitespace to single space
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.trim();
  }

  // ── Command classification ─────────────────────────────────────

  /// Maps raw speech text to a [VoiceCommandType]. Supports English
  /// and Arabic equivalents.
  VoiceCommandType _classify(String text) {
    final lower = text.toLowerCase().trim();
    final arabic = _normalizeArabic(text);

    // English commands
    if (_matchesAny(lower, ['start assistance', 'start', 'begin'])) {
      return VoiceCommandType.startAssistance;
    }
    if (_matchesAny(lower, ['stop assistance', 'stop', 'halt'])) {
      return VoiceCommandType.stopAssistance;
    }
    if (_matchesAny(lower, ['repeat', 'say again', 'again'])) {
      return VoiceCommandType.repeat;
    }
    if (_matchesAny(lower, ['device status', 'status', 'devices'])) {
      return VoiceCommandType.deviceStatus;
    }
    if (_matchesAny(lower, ['settings', 'preferences', 'options'])) {
      return VoiceCommandType.settings;
    }
    if (_matchesAny(lower, ['emergency', 'help', 'sos'])) {
      return VoiceCommandType.emergency;
    }

    // Arabic commands (normalized)
    if (_matchesAny(arabic, [
      'ابدأ المساعده',
      'ابدأ المساعده',
      'ابدأ المساعده',
      'ابدا المساعده',
      'ابدأ',
      'ابدا',
      'ابدء',
    ])) {
      return VoiceCommandType.startAssistance;
    }
    if (_matchesAny(arabic, [
      'اوقف المساعده',
      'اوقف المساعده',
      'توقف',
      'اوقف',
      'وقف',
    ])) {
      return VoiceCommandType.stopAssistance;
    }
    if (_matchesAny(arabic, ['كرر', 'اعاده', 'اعيد', 'مره اخرى', 'كرري'])) {
      return VoiceCommandType.repeat;
    }
    if (_matchesAny(arabic, [
      'حاله الاجهزه',
      'الاجهزه',
      'حاله',
      'الجهاز',
      'حالة الأجهزة',
      'حالة الأجهزة',
    ])) {
      return VoiceCommandType.deviceStatus;
    }
    if (_matchesAny(arabic, [
      'الاعدادات',
      'الاعدادت',
      'الاعداد',
      'ضبط',
      'الاعدادات',
    ])) {
      return VoiceCommandType.settings;
    }
    if (_matchesAny(arabic, [
      'طوارئ',
      'النجده',
      'المساعده',
      'طواري',
      'طوارئ',
    ])) {
      return VoiceCommandType.emergency;
    }

    // Confirmation responses
    if (_matchesAny(lower, ['yes', 'confirm'])) {
      return VoiceCommandType.confirmYes;
    }
    if (_matchesAny(lower, ['no', 'false', 'cancel'])) {
      return VoiceCommandType.confirmNo;
    }
    if (_matchesAny(arabic, ['نعم', 'اجل', 'ايه', 'صحيح'])) {
      return VoiceCommandType.confirmYes;
    }
    if (_matchesAny(arabic, ['لا', 'الغاء', 'لأ', 'لالا', 'لا لا'])) {
      return VoiceCommandType.confirmNo;
    }

    return VoiceCommandType.unrecognized;
  }

  bool _matchesAny(String input, List<String> patterns) {
    return patterns.any(input.contains);
  }

  // ── Raw speech handling ────────────────────────────────────────

  void _onRawSpeechResult(SpeechResult result) {
    if (result.text.trim().isEmpty) return;

    // Stop the current recognition session only.
    // Voice Ready Mode is NOT disabled here.
    _voiceService.stopListening();

    _state = VoiceCommandState.processing;
    notifyListeners();

    final type = _classify(result.text);
    final command = VoiceCommand(
      type: type,
      rawText: result.text,
      confidence: result.confidence,
      localeId: _localeId,
    );

    _lastCommand = command;

    // Handle confirmation flow
    if (_pendingConfirmation != VoiceCommandType.unrecognized) {
      _resolveConfirmation(command);
      return;
    }

    // Handle emergency special case
    if (type == VoiceCommandType.emergency) {
      _handleEmergency();
      return;
    }

    // Emit command for the router
    _emitCommand(command);

    _state = VoiceCommandState.idle;
    notifyListeners();

    if (_voiceReadyMode) {
      _scheduleNextSession();
    }
  }

  // ── Session end (no result) ────────────────────────────────────

  void _onSessionEnded() {
    if (!_voiceReadyMode) return;
    // Only restart if we were still in listening state — meaning no
    // result was received (timeout / noMatch / silence).
    if (_state == VoiceCommandState.listening) {
      _state = VoiceCommandState.idle;
      notifyListeners();
      _scheduleNextSession();
    }
  }

  // ── Voice Ready Mode restart logic ─────────────────────────────

  void _scheduleNextSession() {
    if (!_voiceReadyMode) return;
    if (_restartTimer != null) return; // already scheduled

    _restartTimer = Timer(const Duration(seconds: 1), () async {
      _restartTimer = null;
      if (!_voiceReadyMode) return;
      if (_state == VoiceCommandState.listening) return;

      // Wait for TTS to finish before starting a new session.
      const maxWait = Duration(seconds: 10);
      const pollInterval = Duration(milliseconds: 100);
      var waited = Duration.zero;
      while (_ttsService.isSpeaking && waited < maxWait) {
        await Future.delayed(pollInterval);
        waited += pollInterval;
      }

      if (!_voiceReadyMode) return;
      if (_state == VoiceCommandState.listening) return;

      await startListening();
    });
  }

  // ── Emergency confirmation ─────────────────────────────────────

  void _handleEmergency() {
    _pendingConfirmation = VoiceCommandType.emergency;
    if (_appLanguage == AppLanguage.arabic) {
      _ttsService.speak('تاكيد الطوارئ؟ قل نعم او لا');
    } else {
      _ttsService.speak('Emergency confirmed? Say yes or no');
    }
    _state = VoiceCommandState.idle;
    notifyListeners();
    if (_voiceReadyMode) {
      _scheduleNextSession();
    }
  }

  void _resolveConfirmation(VoiceCommand command) {
    final pending = _pendingConfirmation;
    _pendingConfirmation = VoiceCommandType.unrecognized;

    if (command.type == VoiceCommandType.confirmYes &&
        pending == VoiceCommandType.emergency) {
      _emitCommand(VoiceCommand(
        type: VoiceCommandType.emergency,
        rawText: command.rawText,
        confidence: command.confidence,
        localeId: command.localeId,
      ));
      if (_appLanguage == AppLanguage.arabic) {
        _ttsService.speak('تم تفعيل الطوارئ');
      } else {
        _ttsService.speak('Emergency activated');
      }
    } else {
      if (_appLanguage == AppLanguage.arabic) {
        _ttsService.speak('تم إلغاء الطوارئ');
      } else {
        _ttsService.speak('Emergency cancelled');
      }
    }

    _state = VoiceCommandState.idle;
    notifyListeners();

    if (_voiceReadyMode) {
      _scheduleNextSession();
    }
  }

  // ── Stream emission ────────────────────────────────────────────

  void _emitCommand(VoiceCommand command) {
    if (!_commandController.isClosed) {
      _commandController.add(command);
    }
  }

  // ── Cleanup ────────────────────────────────────────────────────

  @override
  void dispose() {
    _voiceReadyMode = false;
    _restartTimer?.cancel();
    _speechSubscription?.cancel();
    _voiceService.stopListening();
    _voiceService.dispose();
    _ttsService.dispose();
    _commandController.close();
    super.dispose();
  }
}
