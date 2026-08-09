import 'package:flutter/material.dart';

abstract final class RelayColors {
  static const background = Color(0xFF0D2233);
  static const backgroundTop = Color(0xFF1E5D87);
  static const backgroundBottom = Color(0xFF242046);
  static const surface = Color(0xFF20465A);
  static const surfaceSoft = Color(0xFF315E74);
  static const surfaceHigh = Color(0xFF3A6D83);
  static const cyan = Color(0xFF53E5FF);
  static const mint = Color(0xFF7AF2C6);
  static const amber = Color(0xFFFFD369);
  static const coral = Color(0xFFFF8291);
  static const magenta = Color(0xFFFF78D7);
  static const violet = Color(0xFFB99BFF);
  static const electricBlue = Color(0xFF74A7FF);
  static const lime = Color(0xFFC4FF7D);
  static const muted = Color(0xFFC0D5E0);
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

  static BoxDecoration modeShell(Color accent) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(accent.withValues(alpha: 0.18), RelayColors.backgroundTop),
          Color.alphaBlend(accent.withValues(alpha: 0.075), RelayColors.background),
          RelayColors.backgroundBottom,
        ],
        stops: const [0.0, 0.48, 1.0],
      ),
    );
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
          Color.alphaBlend(accent.withValues(alpha: soft ? 0.14 : 0.20), RelayColors.surface),
          Color.alphaBlend(accent.withValues(alpha: soft ? 0.075 : 0.105), RelayColors.surfaceSoft),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.38)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.13),
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
          Color(0xFF1C7183),
          Color(0xFF31548C),
          Color(0xFF543E78),
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
        toolbarHeight: 64,
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return RelayColors.cyan.withValues(alpha: 0.18);
            }
            return RelayColors.surfaceSoft.withValues(alpha: 0.64);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? RelayColors.white
                : RelayColors.muted;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.selected)
                  ? RelayColors.cyan.withValues(alpha: 0.62)
                  : RelayColors.cyan.withValues(alpha: 0.18),
            );
          }),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RelayColors.surfaceSoft.withValues(alpha: 0.72),
        selectedColor: RelayColors.violet.withValues(alpha: 0.20),
        side: BorderSide(color: RelayColors.cyan.withValues(alpha: 0.18)),
        labelStyle: const TextStyle(color: RelayColors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RelayColors.cyan,
        linearTrackColor: Color(0xFF264656),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return RelayColors.cyan.withValues(alpha: 0.18);
            }
            return RelayColors.surfaceSoft.withValues(alpha: 0.72);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return RelayColors.white;
            return RelayColors.muted;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected)
                ? RelayColors.cyan.withValues(alpha: 0.72)
                : RelayColors.violet.withValues(alpha: 0.22);
            return BorderSide(color: color, width: states.contains(WidgetState.selected) ? 1.5 : 1);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.55, fontSize: 11),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RelayColors.surfaceSoft.withValues(alpha: 0.76),
        selectedColor: RelayColors.cyan.withValues(alpha: 0.18),
        side: BorderSide(color: RelayColors.violet.withValues(alpha: 0.24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: RelayColors.white, fontWeight: FontWeight.w800),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RelayColors.surfaceHigh.withValues(alpha: 0.96),
        contentTextStyle: const TextStyle(color: RelayColors.white),
      ),
    );
  }
}
