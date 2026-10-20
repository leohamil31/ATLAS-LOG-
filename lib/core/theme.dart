/// Design system do Atlas: paleta slate (dark/light), acentos ciano/azul,
/// tipografia Inter e extensões para acessar as cores a partir do contexto.
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
    bg: Color(0xFF0F172A), // slate-900
    surface: Color(0xFF111C33),
    card: Color(0xFF1E293B), // slate-800
    border: Color(0xFF334155), // slate-700
    text: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    accent: Color(0xFF22D3EE), // ciano neon
    accent2: Color(0xFF3B82F6),
    success: Color(0xFF34D399), // esmeralda
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
  );

  static const lightPalette = AtlasColors(
    dark: false,
    bg: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    accent: Color(0xFF0891B2),
    accent2: Color(0xFF2563EB),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
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
    splashFactory: InkRipple.splashFactory,
  );
  final text = webFonts
      ? GoogleFonts.interTextTheme(base.textTheme)
      : base.textTheme;
  return base.copyWith(
    textTheme: text.apply(bodyColor: c.text, displayColor: c.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      hintStyle: TextStyle(color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.6),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF0B1220) : c.text,
      contentTextStyle: TextStyle(
        color: dark ? c.text : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
