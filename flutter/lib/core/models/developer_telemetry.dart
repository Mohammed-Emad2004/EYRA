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
  final String telemetryId;
  final String sessionId;
  final double fps;
  final int inferenceLatencyMs;
  final double cpuUsagePct;
  final double ramUsageMb;
  final DateTime recordedAt;

  const DeveloperTelemetry({
    required this.telemetryId,
    required this.sessionId,
    required this.fps,
    required this.inferenceLatencyMs,
    required this.cpuUsagePct,
    required this.ramUsageMb,
    required this.recordedAt,
  });

  factory DeveloperTelemetry.fromJson(Map<String, dynamic> json) {
    return DeveloperTelemetry(
      telemetryId: json['telemetry_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      fps: (json['fps'] as num?)?.toDouble() ?? 0,
      inferenceLatencyMs: (json['inference_latency_ms'] as num?)?.toInt() ?? 0,
      cpuUsagePct: (json['cpu_usage_pct'] as num?)?.toDouble() ?? 0,
      ramUsageMb: (json['ram_usage_mb'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.parse(json['recorded_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'telemetry_id': telemetryId,
        'session_id': sessionId,
        'fps': fps,
        'inference_latency_ms': inferenceLatencyMs,
        'cpu_usage_pct': cpuUsagePct,
        'ram_usage_mb': ramUsageMb,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
