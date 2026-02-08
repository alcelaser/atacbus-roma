import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/preferences_storage.dart';
import 'sync_provider.dart';

/// Notifier that manages the app's ThemeMode and persists it.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesStorage _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final mode = await _prefs.getThemeMode();
    state = _fromString(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(_toString(mode));
  }

  static ThemeMode _fromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(preferencesStorageProvider);
  return ThemeModeNotifier(prefs);
});

final lastSyncDateProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = ref.watch(preferencesStorageProvider);
  return prefs.getLastSyncDate();
});
