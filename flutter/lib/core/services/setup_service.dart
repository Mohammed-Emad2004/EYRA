import '../models/setup_progress.dart';

/// Abstraction boundary for onboarding/setup progress.
///
/// [SetupController] depends only on this interface, never on local
/// storage or a backend directly. Today the only implementation is
/// [MockSetupService] (see `mock/mock_setup_service.dart`), which keeps
/// progress in memory for the lifetime of the app. A future backend
/// implementation, persisting to the `Setup Steps` table, can implement
/// this same interface and be swapped in without changing
/// [SetupController] or any onboarding screen.
abstract class SetupService {
  Future<SetupProgress> getProgress(String userId);
  Future<void> saveProgress(SetupProgress progress);
}
