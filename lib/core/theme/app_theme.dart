import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'text_theme.dart';

/// Assembles the complete light and dark [ThemeData] for the BUS - Roma
/// app, wiring together colour schemes, text themes, and component-level
/// overrides.
class AppTheme {
  AppTheme._(); // prevent instantiation

  /// Light theme suitable for daytime usage.
  static ThemeData lightTheme() {
    final colorScheme = AppColorSchemes.lightColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.textTheme(),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondary,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
    );
  }

  /// Dark theme suitable for night mode.
  static ThemeData darkTheme() {
    final colorScheme = AppColorSchemes.darkColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.textTheme(),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondary,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
    );
  }
}
