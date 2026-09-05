/// Domain model for developer/diagnostic telemetry, shown on the
/// Developer Monitor screen.
///
/// Maps to the `developer_telemetry` table in the backend ERD.
///
/// AMBIGUOUS SCHEMA NOTE: the ERD shows TWO telemetry-shaped boxes - a
/// clearer one titled "developer_telemetry" (bottom-left) whose columns
/// match the product's telemetry concepts (OCR language, speech
/// rate/pitch/volume, TTS voice gender, haptic %, usage %, dropped
/// scans, network latency), and a second, heavily garbled box titled
/// "Developer Telemetry" (bottom-right) whose legible columns
/// (contact_name, relationship, phone_number) look like they were
/// copied from the Emergency Contact table rather than genuine telemetry
/// fields. This model is built from the clearer "developer_telemetry"
/// box; the second box's content is treated as unreliable/likely a
/// rendering artifact and is NOT represented here - see architecture
/// notes, requires confirmation.
///
/// A second ambiguity: the clearer box's primary key is `user_id`
/// (suggesting one row per user), while the product/task description
/// implies telemetry should be recorded per assistance session (with
/// its own `telemetry_id` and `session_id`). This model keeps both an
/// optional [id]/[sessionId] (for a future per-session grain) and a
/// required [userId] (matching what is actually legible in the ERD),
/// pending confirmation of the real primary key/grain.
///
/// Database mapping (see ERD `developer_telemetry` table):
/// - `user_id`               -> [userId]
/// - (timestamp column)      -> [recordedAt]. AMBIGUOUS: rendered as
///   "telemetrd_at" - read as a recorded-at timestamp.
/// - `ocr_language`          -> [ocrLanguage]. ENUM values not legible.
/// - `speech_rate`           -> [speechRate]
/// - (pitch column)          -> [speechPitch]. Rendered as "speech_nitch"
///   - read as "speech_pitch".
/// - `speech_volume`         -> [speechVolume]
/// - `tts_voice_gender`      -> [ttsVoiceGender]. ENUM values not legible.
/// - (haptic % column)       -> [hapticPercentage]. Rendered as
///   "haptic_perconntage" - read as "haptic_percentage".
/// - (usage % column)        -> [usagePercentage]. Rendered as
///   "usag_percentage" - read as "usage_percentage".
/// - (dropped scans column)  -> [droppedScans]. Rendered as
///   "droped_cans" - read as "dropped_scans".
/// - `network_latency`       -> [networkLatencyMs]
///
/// App-local fields (current Developer Monitor screen, not present in
/// the ERD's `developer_telemetry` table): [fps], [inferenceMs],
/// [totalLatencyMs], [modelName]. These back the existing performance
/// tile grid and are kept so existing product behavior is not removed;
/// if the backend later adds matching columns, they can be wired
/// directly.
class DeveloperTelemetry {
  final String? id;
  final String? sessionId;
  final String userId;
  final DateTime? recordedAt;
  final String? ocrLanguage;
  final double? speechRate;
  final double? speechPitch;
  final double? speechVolume;
  final String? ttsVoiceGender;
  final double? hapticPercentage;
  final double? usagePercentage;
  final bool? droppedScans;
  final int? networkLatencyMs;

  // --- App-local (existing Developer Monitor screen; not in ERD) ---
  final double? fps;
  final int? inferenceMs;
  final int? totalLatencyMs;
  final String? modelName;

  const DeveloperTelemetry({
    this.id,
    this.sessionId,
    required this.userId,
    this.recordedAt,
    this.ocrLanguage,
    this.speechRate,
    this.speechPitch,
    this.speechVolume,
    this.ttsVoiceGender,
    this.hapticPercentage,
    this.usagePercentage,
    this.droppedScans,
    this.networkLatencyMs,
    this.fps,
    this.inferenceMs,
    this.totalLatencyMs,
    this.modelName,
  });
}
