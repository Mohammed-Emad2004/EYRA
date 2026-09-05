/// Abstraction boundary for where accessibility & preference settings are
/// persisted, at the raw key-value level.
///
/// [MockSettingsService] depends on this interface, never on
/// `shared_preferences` (or any other storage API) directly. Today the
/// only implementation is [SharedPreferencesSettingsStorageService] (see
/// `local/shared_preferences_settings_storage_service.dart`), which keeps
/// settings on-device. This sits one layer below the domain-level
/// [SettingsService] that [AppSettingsController] actually depends on.
abstract class SettingsStorageService {
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
}
