import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_settings.dart';
import '../settings_service.dart';

/// Firestore-backed implementation of [SettingsService].
///
/// Dual-write strategy:
/// - Reads: Firestore first, falls back to SharedPreferences cache.
/// - Writes: Firestore (account-level, excl. themeMode) + SharedPreferences
///   (local cache, incl. themeMode).
///
/// `themeMode` is a local-only preference — never written to Firestore.
class FirestoreSettingsService implements SettingsService {
  FirestoreSettingsService({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final String _userId;
  final FirebaseFirestore _firestore;

  static const _keyThemeMode = 'eyra.themeMode';

  DocumentReference get _settingsDoc =>
      _firestore.collection('users').doc(_userId).collection('settings').doc('profile');

  @override
  Future<UserSettings> loadSettings() async {
    UserSettings? firestoreSettings;

    // Try Firestore first (account-level settings)
    try {
      final doc = await _settingsDoc.get();
      if (doc.exists) {
        firestoreSettings = UserSettings.fromFirestore(doc);
      }
    } catch (_) {
      // Firestore unavailable — fall through to local cache
    }

    // Load themeMode from SharedPreferences (local-only)
    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_keyThemeMode);
    final themeMode = AppThemeMode.values.firstWhere(
      (m) => m.name == themeModeName,
      orElse: () => AppThemeMode.system,
    );

    if (firestoreSettings != null) {
      // Merge: Firestore settings + local themeMode
      return firestoreSettings.copyWith(themeMode: themeMode);
    }

    // Firestore unavailable — fall back to SharedPreferences for all fields
    final localSettings = await _loadFromSharedPreferences(prefs);
    return localSettings.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    // Write to Firestore: all fields EXCEPT themeMode, settingId, userId
    try {
      await _settingsDoc.set(settings.toFirestore(), SetOptions(merge: true));
    } catch (_) {
      // Firestore unavailable — local cache still updated below
    }

    // Write to SharedPreferences: all fields (including themeMode) as cache
    await _saveToSharedPreferences(prefs, settings);
  }

  /// Reads all settings from SharedPreferences (used as offline fallback).
  Future<UserSettings> _loadFromSharedPreferences(SharedPreferences prefs) async {
    final languageCode = prefs.getString('eyra.language');
    final language =
        languageCode == 'ar' ? AppLanguage.arabic : AppLanguage.english;

    final voiceAlerts = prefs.getBool('eyra.voiceAlerts') ?? true;

    final freqName = prefs.getString('eyra.alertFrequency');
    final alertFrequency = AlertFrequency.values.firstWhere(
      (f) => f.name == freqName,
      orElse: () => AlertFrequency.normal,
    );

    final highContrast = prefs.getBool('eyra.highContrast') ?? false;
    final largeText = prefs.getBool('eyra.largeText') ?? false;
    final hapticFeedback = prefs.getBool('eyra.haptics') ?? true;

    return UserSettings(
      language: language,
      voiceAlerts: voiceAlerts,
      alertFrequency: alertFrequency,
      highContrast: highContrast,
      largeText: largeText,
      hapticFeedback: hapticFeedback,
    );
  }

  /// Writes all settings to SharedPreferences (local cache).
  Future<void> _saveToSharedPreferences(
    SharedPreferences prefs,
    UserSettings settings,
  ) async {
    await prefs.setString(
      'eyra.language',
      settings.language == AppLanguage.arabic ? 'ar' : 'en',
    );
    await prefs.setBool('eyra.voiceAlerts', settings.voiceAlerts);
    await prefs.setString('eyra.alertFrequency', settings.alertFrequency.name);
    await prefs.setBool('eyra.highContrast', settings.highContrast);
    await prefs.setBool('eyra.largeText', settings.largeText);
    await prefs.setBool('eyra.haptics', settings.hapticFeedback);
    await prefs.setString(_keyThemeMode, settings.themeMode.name);
  }
}
