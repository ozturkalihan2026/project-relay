import 'package:flutter/material.dart';

abstract final class RelayColors {
  static const background = Color(0xFF07131A);
  static const surface = Color(0xFF10232D);
  static const surfaceHigh = Color(0xFF193743);
  static const cyan = Color(0xFF38E8FF);
  static const mint = Color(0xFF5DF2A9);
  static const amber = Color(0xFFFFC857);
  static const coral = Color(0xFFFF6B6B);
  static const muted = Color(0xFF8CA6B2);
}

abstract final class RelayTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RelayColors.cyan,
      brightness: Brightness.dark,
      surface: RelayColors.surface,
      error: RelayColors.coral,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RelayColors.background,
      fontFamily: 'Roboto',
      cardTheme: const CardThemeData(
        color: RelayColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFF245161)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: RelayColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RelayColors.cyan,
          foregroundColor: RelayColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RelayColors.surfaceHigh,
      ),
    );
  }
}
