import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, arabic }

enum AlertFrequency { low, normal, high }

extension AlertFrequencyLabel on AlertFrequency {
  String get label {
    switch (this) {
      case AlertFrequency.low:
        return 'Low';
      case AlertFrequency.normal:
        return 'Normal';
      case AlertFrequency.high:
        return 'High';
    }
  }
}

/// Holds all user-facing accessibility & preference settings.
///
/// State is kept in memory and persisted locally via [SharedPreferences].
/// There is no backend, cloud sync, or account server involved.
class AppSettingsController extends ChangeNotifier {
  static const _keyLanguage = 'eyra.language';
  static const _keyVoiceAlerts = 'eyra.voiceAlerts';
  static const _keyAlertFrequency = 'eyra.alertFrequency';
  static const _keyHighContrast = 'eyra.highContrast';
  static const _keyLargeText = 'eyra.largeText';
  static const _keyHaptics = 'eyra.haptics';

  AppLanguage _language = AppLanguage.english;
  bool _voiceAlerts = true;
  AlertFrequency _alertFrequency = AlertFrequency.normal;
  bool _highContrast = false;
  bool _largeText = false;
  bool _hapticFeedback = true;

  bool _isLoaded = false;

  AppLanguage get language => _language;
  bool get voiceAlerts => _voiceAlerts;
  AlertFrequency get alertFrequency => _alertFrequency;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get hapticFeedback => _hapticFeedback;
  bool get isLoaded => _isLoaded;

  TextDirection get textDirection =>
      _language == AppLanguage.arabic ? TextDirection.rtl : TextDirection.ltr;

  Locale get locale =>
      _language == AppLanguage.arabic ? const Locale('ar') : const Locale('en');

  static AppSettingsController of(BuildContext context, {bool listen = false}) {
    return Provider.of<AppSettingsController>(context, listen: listen);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_keyLanguage);
    _language = languageCode == 'ar' ? AppLanguage.arabic : AppLanguage.english;
    _voiceAlerts = prefs.getBool(_keyVoiceAlerts) ?? true;
    final freq = prefs.getString(_keyAlertFrequency);
    _alertFrequency = AlertFrequency.values.firstWhere(
      (f) => f.name == freq,
      orElse: () => AlertFrequency.normal,
    );
    _highContrast = prefs.getBool(_keyHighContrast) ?? false;
    _largeText = prefs.getBool(_keyLargeText) ?? false;
    _hapticFeedback = prefs.getBool(_keyHaptics) ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language == AppLanguage.arabic ? 'ar' : 'en');
  }

  Future<void> setVoiceAlerts(bool value) async {
    _voiceAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceAlerts, value);
  }

  Future<void> setAlertFrequency(AlertFrequency value) async {
    _alertFrequency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAlertFrequency, value.name);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, value);
  }

  Future<void> setLargeText(bool value) async {
    _largeText = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLargeText, value);
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, value);
  }
}
