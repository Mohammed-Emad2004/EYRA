import '../../models/setup_progress.dart';
import '../setup_service.dart';

/// Local in-memory mock implementation of [SetupService].
///
/// Keeps a single [SetupProgress] per app run - it is not persisted
/// across restarts, matching the current onboarding flow's mock
/// behavior (onboarding is shown again after a fresh sign-up).
class MockSetupService implements SetupService {
  final Map<String, SetupProgress> _progressByUser = {};

  @override
  Future<SetupProgress> getProgress(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _progressByUser[userId] ?? SetupProgress(userId: userId);
  }

  @override
  Future<void> saveProgress(SetupProgress progress) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _progressByUser[progress.userId] = progress.copyWith(updatedAt: DateTime.now());
  }
}
