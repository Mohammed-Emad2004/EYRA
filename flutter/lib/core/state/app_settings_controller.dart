import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_settings.dart';
import '../services/mock/mock_settings_service.dart';
import '../services/settings_service.dart';

// Re-exported so existing imports of `app_settings_controller.dart`
// (e.g. in `core/l10n/app_strings.dart` and the Settings screen) keep
// working unchanged now that these enums live on the domain model.
export '../models/user_settings.dart'
    show AppLanguage, AppThemeMode, AlertFrequency, AlertFrequencyLabel;

/// Holds all user-facing accessibility & preference settings.
///
/// This controller is the abstraction boundary the Settings screen
/// depends on. It never talks to storage or a backend directly - it
/// delegates loading/saving a [UserSettings] to an injected
/// [SettingsService]. By default that is [MockSettingsService] (which
/// persists on-device), but a future `RemoteSettingsService` backed by
/// the `User Settings` table can be passed in instead without changing
/// this class or the Settings screen.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController({SettingsService? settingsService})
      : _settingsService = settingsService ?? MockSettingsService();

  final SettingsService _settingsService;

  UserSettings _settings = const UserSettings();
  bool _isLoaded = false;

  AppLanguage get language => _settings.language;
  bool get voiceAlerts => _settings.voiceAlerts;
  AlertFrequency get alertFrequency => _settings.alertFrequency;
  bool get highContrast => _settings.highContrast;
  bool get largeText => _settings.largeText;
  bool get hapticFeedback => _settings.hapticFeedback;
  AppThemeMode get themeMode => _settings.themeMode;
  bool get isLoaded => _isLoaded;

  /// The full domain settings model, for callers that need
  /// backend-shaped fields beyond the simple getters above.
  UserSettings get settings => _settings;

  TextDirection get textDirection => _settings.language == AppLanguage.arabic
      ? TextDirection.rtl
      : TextDirection.ltr;

  Locale get locale => _settings.language == AppLanguage.arabic
      ? const Locale('ar')
      : const Locale('en');

  static AppSettingsController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AppSettingsController>(context, listen: listen);
  }

  Future<void> load() async {
    _settings = await _settingsService.loadSettings();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(language: language);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setVoiceAlerts(bool value) async {
    _settings = _settings.copyWith(voiceAlerts: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setAlertFrequency(AlertFrequency value) async {
    _settings = _settings.copyWith(alertFrequency: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setHighContrast(bool value) async {
    _settings = _settings.copyWith(highContrast: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setLargeText(bool value) async {
    _settings = _settings.copyWith(largeText: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setHapticFeedback(bool value) async {
    _settings = _settings.copyWith(hapticFeedback: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }

  Future<void> setThemeMode(AppThemeMode value) async {
    _settings = _settings.copyWith(themeMode: value);
    notifyListeners();
    await _settingsService.saveSettings(_settings);
  }
}
