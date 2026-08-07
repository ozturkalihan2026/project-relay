import 'package:flutter/material.dart';

abstract final class RelayColors {
  static const background = Color(0xFF08111B);
  static const backgroundTop = Color(0xFF10294A);
  static const backgroundBottom = Color(0xFF0B1826);
  static const surface = Color(0xFF142838);
  static const surfaceSoft = Color(0xFF1C3446);
  static const surfaceHigh = Color(0xFF24495D);
  static const cyan = Color(0xFF46E7FF);
  static const mint = Color(0xFF72F0B7);
  static const amber = Color(0xFFFFD166);
  static const coral = Color(0xFFFF7A7A);
  static const magenta = Color(0xFFFF6BD6);
  static const violet = Color(0xFFB092FF);
  static const muted = Color(0xFFA7C1D2);
  static const white = Color(0xFFF4FBFF);
}

abstract final class RelayDecorations {
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      RelayColors.backgroundTop,
      RelayColors.background,
      RelayColors.backgroundBottom,
    ],
    stops: [0.0, 0.52, 1.0],
  );

  static BoxDecoration appBackground() {
    return const BoxDecoration(gradient: appBackgroundGradient);
  }

  static BoxDecoration screenShell() {
    return const BoxDecoration(gradient: appBackgroundGradient);
  }

  static BoxDecoration panel({
    Color accent = RelayColors.cyan,
    bool soft = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(accent.withValues(alpha: soft ? 0.12 : 0.16), RelayColors.surface),
          Color.alphaBlend(accent.withValues(alpha: soft ? 0.06 : 0.08), RelayColors.surfaceSoft),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.30)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.10),
          blurRadius: 26,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
        const BoxShadow(
          color: Color(0x22000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration heroPanel() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B5068),
          Color(0xFF20375B),
          Color(0xFF31294C),
        ],
      ),
    );
  }

  static BoxDecoration accentHalo(Color color) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.14),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.34),
          blurRadius: 28,
          spreadRadius: -5,
        ),
      ],
    );
  }
}

abstract final class RelayTheme {
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RelayColors.cyan,
      brightness: Brightness.dark,
      surface: RelayColors.surface,
      error: RelayColors.coral,
    ).copyWith(
      primary: RelayColors.cyan,
      secondary: RelayColors.mint,
      tertiary: RelayColors.amber,
      onPrimary: RelayColors.background,
      onSecondary: RelayColors.background,
      onTertiary: RelayColors.background,
      surface: RelayColors.surface,
      onSurface: RelayColors.white,
      error: RelayColors.coral,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: RelayColors.surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: RelayColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: RelayColors.surface.withValues(alpha: 0.88),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFF2B566A)),
        ),
      ),
      dividerColor: RelayColors.muted.withValues(alpha: 0.18),
      iconTheme: const IconThemeData(color: RelayColors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RelayColors.surfaceHigh.withValues(alpha: 0.84),
        hintStyle: const TextStyle(color: RelayColors.muted),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0x3538E8FF)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: RelayColors.cyan, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RelayColors.cyan,
          foregroundColor: RelayColors.background,
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RelayColors.white,
          side: BorderSide(color: RelayColors.cyan.withValues(alpha: 0.40)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: RelayColors.surfaceSoft.withValues(alpha: 0.78),
          foregroundColor: RelayColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: RelayColors.cyan.withValues(alpha: 0.20)),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RelayColors.cyan,
        linearTrackColor: Color(0xFF264656),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RelayColors.surfaceHigh.withValues(alpha: 0.96),
        contentTextStyle: const TextStyle(color: RelayColors.white),
      ),
    );
  }
}
