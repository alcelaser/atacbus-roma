import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class PreferencesStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<DateTime?> getLastSyncDate() async {
    final prefs = await _instance;
    final millis = prefs.getInt(AppConstants.prefsKeyLastSync);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSyncDate(DateTime date) async {
    final prefs = await _instance;
    await prefs.setInt(AppConstants.prefsKeyLastSync, date.millisecondsSinceEpoch);
  }

  Future<String> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.prefsKeyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.prefsKeyThemeMode, mode);
  }

  Future<bool> hasCompletedSync() async {
    final date = await getLastSyncDate();
    return date != null;
  }
}
