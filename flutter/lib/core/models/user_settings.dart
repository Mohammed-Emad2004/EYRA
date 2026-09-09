import 'package:cloud_firestore/cloud_firestore.dart';

/// Theme mode preference. Not a backend schema column — stored locally.
enum AppThemeMode { light, dark, system }

/// The two languages Eyra supports. Matches the schema's
/// `language ENUM('en','ar')`.
enum AppLanguage { english, arabic }

extension AppLanguageValue on AppLanguage {
  String get value {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.arabic:
        return 'ar';
    }
  }

  static AppLanguage fromValue(String? value) {
    switch (value) {
      case 'ar':
        return AppLanguage.arabic;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}

/// How often spoken obstacle alerts should be given.
///
/// Maps to `alert_frequency ENUM('low','normal','high')`.
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

/// Domain model for a user's settings/preferences.
///
/// Maps to the `user_settings` table in the backend schema.
///
/// Database mapping (`user_settings` table):
/// - `setting_id`     -> [settingId]
/// - `user_id`        -> [userId]
/// - `voice_alerts`   -> [voiceAlerts]
/// - `alert_frequency` -> [alertFrequency]
/// - `language`       -> [appLanguage]
/// - `high_contrast`  -> [highContrast]
/// - `large_text`     -> [largeText]
/// - `haptic_feedback` -> [hapticFeedback]
/// - `updated_at`     -> [updatedAt]
class UserSettings {
  final String? settingId;
  final String? userId;
  final bool voiceAlerts;
  final AlertFrequency alertFrequency;
  final AppLanguage language;
  final bool highContrast;
  final bool largeText;
  final bool hapticFeedback;
  final AppThemeMode themeMode;
  final DateTime? updatedAt;

  const UserSettings({
    this.settingId,
    this.userId,
    this.voiceAlerts = true,
    this.alertFrequency = AlertFrequency.normal,
    this.language = AppLanguage.english,
    this.highContrast = false,
    this.largeText = false,
    this.hapticFeedback = true,
    this.themeMode = AppThemeMode.system,
    this.updatedAt,
  });

  UserSettings copyWith({
    String? settingId,
    String? userId,
    bool? voiceAlerts,
    AlertFrequency? alertFrequency,
    AppLanguage? language,
    bool? highContrast,
    bool? largeText,
    bool? hapticFeedback,
    AppThemeMode? themeMode,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      settingId: settingId ?? this.settingId,
      userId: userId ?? this.userId,
      voiceAlerts: voiceAlerts ?? this.voiceAlerts,
      alertFrequency: alertFrequency ?? this.alertFrequency,
      language: language ?? this.language,
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      settingId: json['setting_id']?.toString(),
      userId: json['user_id']?.toString(),
      voiceAlerts: json['voice_alerts'] as bool? ?? true,
      alertFrequency: AlertFrequency.values.firstWhere(
        (f) => f.name == json['alert_frequency'],
        orElse: () => AlertFrequency.normal,
      ),
      language: AppLanguageValue.fromValue(json['language'] as String?),
      highContrast: json['high_contrast'] as bool? ?? false,
      largeText: json['large_text'] as bool? ?? false,
      hapticFeedback: json['haptic_feedback'] as bool? ?? true,
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == json['theme_mode'],
        orElse: () => AppThemeMode.system,
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setting_id': settingId,
      'user_id': userId,
      'voice_alerts': voiceAlerts,
      'alert_frequency': alertFrequency.name,
      'language': language.value,
      'high_contrast': highContrast,
      'large_text': largeText,
      'haptic_feedback': hapticFeedback,
      'theme_mode': themeMode.name,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Serializes for Firestore `users/{uid}/settings/profile` document.
  /// Omits `settingId`, `userId` (path expresses relationship), and
  /// `themeMode` (local-only preference, never stored in Firestore).
  Map<String, dynamic> toFirestore() {
    return {
      'voice_alerts': voiceAlerts,
      'alert_frequency': alertFrequency.name,
      'language': language.value,
      'high_contrast': highContrast,
      'large_text': largeText,
      'haptic_feedback': hapticFeedback,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Deserializes from a Firestore `users/{uid}/settings/profile` document.
  /// `themeMode` is NOT read from Firestore — it is loaded separately
  /// from SharedPreferences (local-only preference).
  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSettings(
      voiceAlerts: data['voice_alerts'] as bool? ?? true,
      alertFrequency: AlertFrequency.values.firstWhere(
        (f) => f.name == data['alert_frequency'],
        orElse: () => AlertFrequency.normal,
      ),
      language: AppLanguageValue.fromValue(data['language'] as String?),
      highContrast: data['high_contrast'] as bool? ?? false,
      largeText: data['large_text'] as bool? ?? false,
      hapticFeedback: data['haptic_feedback'] as bool? ?? true,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
