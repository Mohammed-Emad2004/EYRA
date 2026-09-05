import '../models/user_settings.dart';

/// Abstraction boundary for loading/saving a user's [UserSettings].
///
/// [AppSettingsController] depends only on this interface, never on
/// `shared_preferences` or any storage/network API directly. Today the
/// only implementation is [MockSettingsService] (see
/// `mock/mock_settings_service.dart`), which persists settings on-device
/// via [SettingsStorageService]. A future `RemoteSettingsService`
/// backed by the `User Settings` backend table can implement this same
/// interface and be swapped in without changing [AppSettingsController]
/// or the Settings screen.
abstract class SettingsService {
  Future<UserSettings> loadSettings();
  Future<void> saveSettings(UserSettings settings);
}
