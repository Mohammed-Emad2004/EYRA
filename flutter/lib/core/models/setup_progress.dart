/// Domain model for onboarding/setup progress.
///
/// Maps to the `Setup Steps` table in the backend ERD.
///
/// Database mapping (see ERD `Setup Steps` table):
/// - `user_id`           -> [userId]
/// - `welcome_passed`    -> [welcomePassed]
/// - `glasses_paired`    -> [glassesPaired]
/// - `audio_connected`   -> [audioConnected]
/// - `camera_tested`     -> [cameraTested]
/// - `is_ready`          -> [isReady]
/// - `completed_at`      -> [completedAt]
/// - `updated_at`        -> [updatedAt]
class SetupProgress {
  final String userId;
  final bool welcomePassed;
  final bool glassesPaired;
  final bool audioConnected;
  final bool cameraTested;
  final bool isReady;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const SetupProgress({
    required this.userId,
    this.welcomePassed = false,
    this.glassesPaired = false,
    this.audioConnected = false,
    this.cameraTested = false,
    this.isReady = false,
    this.completedAt,
    this.updatedAt,
  });

  SetupProgress copyWith({
    bool? welcomePassed,
    bool? glassesPaired,
    bool? audioConnected,
    bool? cameraTested,
    bool? isReady,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return SetupProgress(
      userId: userId,
      welcomePassed: welcomePassed ?? this.welcomePassed,
      glassesPaired: glassesPaired ?? this.glassesPaired,
      audioConnected: audioConnected ?? this.audioConnected,
      cameraTested: cameraTested ?? this.cameraTested,
      isReady: isReady ?? this.isReady,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
