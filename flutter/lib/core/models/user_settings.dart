/// The two languages Eyra supports. Matches the ERD's
/// `User Settings.app_language ENUM('ar','en')` exactly.
enum AppLanguage { english, arabic }

/// How often spoken obstacle alerts should be given.
///
/// APP-LOCAL CONCEPT: this does not correspond to any column visible in
/// the `User Settings` table in the ERD. It is kept because it is part
/// of the current, shipping Settings screen and existing product
/// behavior must not be removed. If the backend later adds a matching
/// column, [UserSettings.alertFrequency] can be wired to it directly.
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
/// Maps to the `User Settings` table in the backend ERD. Fields are
/// split into two groups:
///
/// 1. Backend-mapped fields, corresponding to columns visible in the
///    ERD's `User Settings` table.
/// 2. App-local fields, which back the current Settings screen but do
///    not correspond to any column visible in the ERD. These are kept so
///    existing product behavior is not removed; they are clearly marked
///    below and in the architecture notes shipped with this refactor.
///
/// Database mapping (see ERD `User Settings` table):
/// - `app_language`         -> [appLanguage] (ENUM('ar','en') matches exactly)
/// - `ocr_language`         -> [ocrLanguage]. AMBIGUOUS: the ERD shows this
///   column's datatype as "FOAT" (garbled "FLOAT"?), which is an unusual
///   type for a language code. Kept as a raw nullable string pending
///   confirmation of the real datatype.
/// - `speech_rate` / `speech_volume` -> [speechRate], [speechVolume].
///   AMBIGUOUS: the ERD appears to show "speech_volume FLOAT" listed
///   twice and no clearly separate "speech_rate" row in this table. Both
///   fields are kept, but which ERD row maps to which requires
///   confirmation.
/// - (haptic column)        -> [hapticFeedbackLevel]. AMBIGUOUS: ERD
///   renders the column name as "haptic_feedback_nl DECIMAL(4,2)" -
///   likely a feedback intensity/level, but the exact name is illegible.
/// - (voice range column)   -> [voiceRangeEnabled]. AMBIGUOUS: ERD
///   renders the column name as "is_voic_rage TINYINT(1)" - read here as
///   a "voice range" toggle per the product's mention of "voice range",
///   but requires confirmation.
/// - `updated_at`           -> [updatedAt]
///
/// App-local fields (current Settings screen, not present in the ERD):
/// - [voiceAlerts], [alertFrequency], [highContrast], [largeText],
///   [hapticFeedbackEnabled].
class UserSettings {
  // --- Backend-mapped (User Settings table) ---
  final AppLanguage appLanguage;
  final String? ocrLanguage;
  final double? speechRate;
  final double? speechVolume;
  final double? hapticFeedbackLevel;
  final bool? voiceRangeEnabled;
  final DateTime? updatedAt;

  // --- App-local (existing Settings screen; not present in ERD) ---
  final bool voiceAlerts;
  final AlertFrequency alertFrequency;
  final bool highContrast;
  final bool largeText;
  final bool hapticFeedbackEnabled;

  const UserSettings({
    this.appLanguage = AppLanguage.english,
    this.ocrLanguage,
    this.speechRate,
    this.speechVolume,
    this.hapticFeedbackLevel,
    this.voiceRangeEnabled,
    this.updatedAt,
    this.voiceAlerts = true,
    this.alertFrequency = AlertFrequency.normal,
    this.highContrast = false,
    this.largeText = false,
    this.hapticFeedbackEnabled = true,
  });

  UserSettings copyWith({
    AppLanguage? appLanguage,
    String? ocrLanguage,
    double? speechRate,
    double? speechVolume,
    double? hapticFeedbackLevel,
    bool? voiceRangeEnabled,
    DateTime? updatedAt,
    bool? voiceAlerts,
    AlertFrequency? alertFrequency,
    bool? highContrast,
    bool? largeText,
    bool? hapticFeedbackEnabled,
  }) {
    return UserSettings(
      appLanguage: appLanguage ?? this.appLanguage,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      speechRate: speechRate ?? this.speechRate,
      speechVolume: speechVolume ?? this.speechVolume,
      hapticFeedbackLevel: hapticFeedbackLevel ?? this.hapticFeedbackLevel,
      voiceRangeEnabled: voiceRangeEnabled ?? this.voiceRangeEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      voiceAlerts: voiceAlerts ?? this.voiceAlerts,
      alertFrequency: alertFrequency ?? this.alertFrequency,
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }
}
