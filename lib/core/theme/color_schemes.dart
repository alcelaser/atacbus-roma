import 'package:flutter/material.dart';

/// Defines the light and dark [ColorScheme] objects for the ATAC Bus Roma app.
///
/// The palette is inspired by the colours of Rome:
/// - **Dark Red (#8B0000)** – evoking terracotta, ancient brick, and the
///   iconic AS Roma crest.
/// - **Gold (#DAA520)** – recalling the gilded domes and imperial grandeur
///   of the Eternal City.
class AppColorSchemes {
  AppColorSchemes._(); // prevent instantiation

  /// Light colour scheme for daytime / default usage.
  static ColorScheme lightColorScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF8B0000),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFDAD5),
      onPrimaryContainer: Color(0xFF3B0000),
      secondary: Color(0xFFDAA520),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFF0C0),
      onSecondaryContainer: Color(0xFF4A3800),
      surface: Color(0xFFFFFBFF),
      onSurface: Color(0xFF201A19),
      surfaceVariant: Color(0xFFF5DDDA),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      background: Color(0xFFFFFBFF),
      onBackground: Color(0xFF201A19),
    );
  }

  /// Dark colour scheme for night mode.
  static ColorScheme darkColorScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFB4AA),
      onPrimary: Color(0xFF690003),
      primaryContainer: Color(0xFF8B0000),
      onPrimaryContainer: Color(0xFFFFDAD5),
      secondary: Color(0xFFFFD700),
      onSecondary: Color(0xFF3D2E00),
      secondaryContainer: Color(0xFF574400),
      onSecondaryContainer: Color(0xFFFFF0C0),
      surface: Color(0xFF201A19),
      onSurface: Color(0xFFEDE0DD),
      surfaceVariant: Color(0xFF534341),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      background: Color(0xFF201A19),
      onBackground: Color(0xFFEDE0DD),
    );
  }
}
