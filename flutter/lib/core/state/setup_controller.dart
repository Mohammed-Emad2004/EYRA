import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/setup_progress.dart';
import '../services/mock/mock_setup_service.dart';
import '../services/setup_service.dart';

/// Onboarding/setup progress state used by the onboarding screens.
///
/// This controller is the abstraction boundary the onboarding screens
/// depend on. It never talks to storage or a backend directly - it
/// delegates to an injected [SetupService]. By default that is
/// [MockSetupService] (in-memory only, matching the current mock
/// onboarding behavior), but a future backend implementation persisting
/// to the `Setup Steps` table can be passed in instead without changing
/// this class or any onboarding screen.
///
/// A fixed mock user id is used since authentication is mocked and the
/// onboarding flow does not currently thread a real user id through.
class SetupController extends ChangeNotifier {
  SetupController({SetupService? setupService, String userId = 'mock-user'})
      : _setupService = setupService ?? MockSetupService(),
        _userId = userId,
        _progress = SetupProgress(userId: userId);

  final SetupService _setupService;
  final String _userId;

  SetupProgress _progress;

  SetupProgress get progress => _progress;

  static SetupController of(BuildContext context, {bool listen = false}) {
    return Provider.of<SetupController>(context, listen: listen);
  }

  Future<void> load() async {
    _progress = await _setupService.getProgress(_userId);
    notifyListeners();
  }

  Future<void> markWelcomePassed() => _update(_progress.copyWith(welcomePassed: true));

  Future<void> markGlassesPaired() => _update(_progress.copyWith(glassesPaired: true));

  Future<void> markAudioConnected() => _update(_progress.copyWith(audioConnected: true));

  Future<void> markCameraTested() => _update(_progress.copyWith(cameraTested: true));

  Future<void> markReady() => _update(
        _progress.copyWith(isReady: true, completedAt: DateTime.now()),
      );

  Future<void> _update(SetupProgress next) async {
    _progress = next;
    notifyListeners();
    await _setupService.saveProgress(_progress);
  }
}
