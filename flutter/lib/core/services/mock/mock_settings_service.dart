import '../../models/user_settings.dart';
import '../local/shared_preferences_settings_storage_service.dart';
import '../settings_service.dart';
import '../settings_storage_service.dart';

/// Local mock/on-device implementation of [SettingsService].
///
/// Translates between the domain [UserSettings] model and simple
/// key-value storage via an injected [SettingsStorageService] (by
/// default [SharedPreferencesSettingsStorageService]). Field names on
/// the wire (the storage keys) are kept stable across app versions.
///
/// A future `RemoteSettingsService implements SettingsService` could
/// sync the same [UserSettings] shape with the `User Settings` backend
/// table instead, without [AppSettingsController] or the Settings
/// screen needing any changes.
class MockSettingsService implements SettingsService {
  MockSettingsService({SettingsStorageService? storage})
      : _storage = storage ?? SharedPreferencesSettingsStorageService();

  final SettingsStorageService _storage;

  static const _keyLanguage = 'eyra.language';
  static const _keyVoiceAlerts = 'eyra.voiceAlerts';
  static const _keyAlertFrequency = 'eyra.alertFrequency';
  static const _keyHighContrast = 'eyra.highContrast';
  static const _keyLargeText = 'eyra.largeText';
  static const _keyHaptics = 'eyra.haptics';
  static const _keyThemeMode = 'eyra.themeMode';

  @override
  Future<UserSettings> loadSettings() async {
    final languageCode = await _storage.getString(_keyLanguage);
    final language =
        languageCode == 'ar' ? AppLanguage.arabic : AppLanguage.english;

    final voiceAlerts = await _storage.getBool(_keyVoiceAlerts) ?? true;

    final freqName = await _storage.getString(_keyAlertFrequency);
    final alertFrequency = AlertFrequency.values.firstWhere(
      (f) => f.name == freqName,
      orElse: () => AlertFrequency.normal,
    );

    final highContrast = await _storage.getBool(_keyHighContrast) ?? false;
    final largeText = await _storage.getBool(_keyLargeText) ?? false;
    final hapticFeedback = await _storage.getBool(_keyHaptics) ?? true;

    final themeModeName = await _storage.getString(_keyThemeMode);
    final themeMode = AppThemeMode.values.firstWhere(
      (m) => m.name == themeModeName,
      orElse: () => AppThemeMode.system,
    );

    return UserSettings(
      language: language,
      voiceAlerts: voiceAlerts,
      alertFrequency: alertFrequency,
      highContrast: highContrast,
      largeText: largeText,
      hapticFeedback: hapticFeedback,
      themeMode: themeMode,
    );
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    await _storage.setString(
      _keyLanguage,
      settings.language == AppLanguage.arabic ? 'ar' : 'en',
    );
    await _storage.setBool(_keyVoiceAlerts, settings.voiceAlerts);
    await _storage.setString(_keyAlertFrequency, settings.alertFrequency.name);
    await _storage.setBool(_keyHighContrast, settings.highContrast);
    await _storage.setBool(_keyLargeText, settings.largeText);
    await _storage.setBool(_keyHaptics, settings.hapticFeedback);
    await _storage.setString(_keyThemeMode, settings.themeMode.name);
  }
}
