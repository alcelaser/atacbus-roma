import 'package:flutter/material.dart';

/// Provides the app-wide [TextTheme].
///
/// Currently returns the default Material 3 type-scale so that every text
/// style automatically follows the M3 guidelines.  Swap in a custom
/// [GoogleFonts] or manual [TextStyle] overrides here when branding requires
/// it.
class AppTextTheme {
  AppTextTheme._(); // prevent instantiation

  /// Default Material 3 text theme (no custom fonts).
  static TextTheme textTheme() {
    return const TextTheme();
  }
}
