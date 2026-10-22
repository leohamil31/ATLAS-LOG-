/// Design system corporativo do ATLAS LOG.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtlasColors {
  const AtlasColors({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accent2,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final bool dark;
  final Color bg;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accent2;
  final Color success;
  final Color warning;
  final Color danger;

  static const darkPalette = AtlasColors(
    dark: true,
    bg: Color(0xFF111827),
    surface: Color(0xFF1F2937),
    card: Color(0xFF1F2937),
    border: Color(0xFF374151),
    text: Color(0xFFF9FAFB),
    muted: Color(0xFF9CA3AF),
    accent: Color(0xFF60A5FA),
    accent2: Color(0xFF3B82F6),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  static const lightPalette = AtlasColors(
    dark: false,
    bg: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E6EA),
    text: Color(0xFF1F2937),
    muted: Color(0xFF667085),
    accent: Color(0xFF2563EB),
    accent2: Color(0xFF1D4ED8),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
  );
}

extension AtlasContext on BuildContext {
  AtlasColors get ac => Theme.of(this).brightness == Brightness.dark
      ? AtlasColors.darkPalette
      : AtlasColors.lightPalette;

  /// Usuário pediu menos movimento (prefers-reduced-motion).
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;
}

ThemeData buildTheme({required bool dark, bool webFonts = true}) {
  final c = dark ? AtlasColors.darkPalette : AtlasColors.lightPalette;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent2,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.accent,
      surface: c.card,
    ),
    dividerColor: c.border,
    splashFactory: InkSparkle.splashFactory,
  );
  final text = webFonts
      ? GoogleFonts.interTextTheme(base.textTheme)
      : base.textTheme;
  return base.copyWith(
    textTheme: text.apply(bodyColor: c.text, displayColor: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        color: c.text,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: c.border),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accent2.withValues(alpha: 0.1),
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      labelStyle: TextStyle(color: c.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent2,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: TextStyle(color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.accent2, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF0B1220) : c.text,
      contentTextStyle: TextStyle(
        color: dark ? c.text : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.border,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(c.border),
    ),
  );
}
