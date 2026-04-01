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

  // ─── Differential sync metadata ──────────────────────────────

  Future<String?> getLastZipHash() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.prefsKeyLastZipHash);
  }

  Future<void> setLastZipHash(String hash) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.prefsKeyLastZipHash, hash);
  }

  Future<Map<String, String>> getFileHashes() async {
    final prefs = await _instance;
    final json = prefs.getString(AppConstants.prefsKeyFileHashes);
    if (json == null) return {};
    // Stored as "key1=val1;key2=val2" to avoid importing dart:convert
    final map = <String, String>{};
    for (final entry in json.split(';')) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  Future<void> setFileHashes(Map<String, String> hashes) async {
    final prefs = await _instance;
    final encoded = hashes.entries.map((e) => '${e.key}=${e.value}').join(';');
    await prefs.setString(AppConstants.prefsKeyFileHashes, encoded);
  }
}
