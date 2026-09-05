import 'package:shared_preferences/shared_preferences.dart';
import '../settings_storage_service.dart';

/// On-device implementation of [SettingsStorageService], backed by
/// `shared_preferences`.
///
/// This is the only place in the app that imports `shared_preferences`
/// directly - [AppSettingsController] and the Settings screen only ever
/// talk to the [SettingsStorageService] interface.
class SharedPreferencesSettingsStorageService implements SettingsStorageService {
  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
