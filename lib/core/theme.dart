/// Design system do ATLAS LOG — tokens de cor, profundidade, raio e movimento.
///
/// Tudo o que é visual parte daqui:
/// * [AtlasColors]  → paleta (ThemeExtension, interpolada na troca claro/escuro)
/// * [AtlasRadius]  → escala de cantos
/// * [AtlasShadows] → camadas de profundidade (soft / raised / glow)
/// * [AtlasMotion]  → durações e curvas padronizadas
/// * [AtlasBreakpoints] → larguras de layout responsivo
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/motion.dart' show AtlasPageTransitionsBuilder;

// ---------------------------------------------------------------------------
// Cores
// ---------------------------------------------------------------------------

class AtlasColors extends ThemeExtension<AtlasColors> {
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
    required this.accent3,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glass,
    required this.shadow,
  });

  final bool dark;

  /// Fundo da aplicação (atrás do gradiente ambiente).
  final Color bg;

  /// Barras, painéis e diálogos.
  final Color surface;

  /// Cards de conteúdo.
  final Color card;
  final Color border;
  final Color text;
  final Color muted;

  /// Destaque para textos/ícones (contraste AA sobre surface).
  final Color accent;

  /// Cor de ação principal (botões, seleção).
  final Color accent2;

  /// Segunda cor do gradiente de marca.
  final Color accent3;
  final Color success;
  final Color warning;
  final Color danger;

  /// Preenchimento translúcido das superfícies de vidro.
  final Color glass;

  /// Base das sombras (tingida, nunca preto puro).
  final Color shadow;

  /// Gradiente de marca usado em botões primários e destaques.
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent2, accent3],
  );

  /// Brilho sutil de borda para superfícies de vidro.
  LinearGradient get glassStroke => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: dark ? 0.14 : 0.9),
      border.withValues(alpha: dark ? 0.5 : 0.7),
    ],
  );

  static const lightPalette = AtlasColors(
    dark: false,
    bg: Color(0xFFF3F6F9),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE1E8EF),
    text: Color(0xFF0E1E33),
    muted: Color(0xFF5A6B80),
    accent: Color(0xFF0E5A9C),
    accent2: Color(0xFF1F6FA8),
    accent3: Color(0xFF2BB3B1),
    success: Color(0xFF0F8A5F),
    warning: Color(0xFFB45309),
    danger: Color(0xFFC0262D),
    glass: Color(0xC7FFFFFF), // ~78%
    shadow: Color(0xFF0E3A6B),
  );

  static const darkPalette = AtlasColors(
    dark: true,
    bg: Color(0xFF06111E),
    surface: Color(0xFF0C1C2E),
    card: Color(0xFF0F2236),
    border: Color(0xFF1C3550),
    text: Color(0xFFEEF4FA),
    muted: Color(0xFF8FA6BF),
    accent: Color(0xFF6FD3CB),
    accent2: Color(0xFF2B7BC0),
    accent3: Color(0xFF2BB3B1),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    glass: Color(0xA60F2236), // ~65%
    shadow: Color(0xFF000000),
  );

  @override
  AtlasColors copyWith({
    bool? dark,
    Color? bg,
    Color? surface,
    Color? card,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? accent2,
    Color? accent3,
    Color? success,
    Color? warning,
    Color? danger,
    Color? glass,
    Color? shadow,
  }) => AtlasColors(
    dark: dark ?? this.dark,
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    card: card ?? this.card,
    border: border ?? this.border,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    accent2: accent2 ?? this.accent2,
    accent3: accent3 ?? this.accent3,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    glass: glass ?? this.glass,
    shadow: shadow ?? this.shadow,
  );

  /// Interpolação usada pelo AnimatedTheme: a troca claro/escuro vira um
  /// crossfade suave em todo o app em vez de um corte seco.
  @override
  AtlasColors lerp(ThemeExtension<AtlasColors>? other, double t) {
    if (other is! AtlasColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AtlasColors(
      dark: t < 0.5 ? dark : other.dark,
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      card: c(card, other.card),
      border: c(border, other.border),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      accent: c(accent, other.accent),
      accent2: c(accent2, other.accent2),
      accent3: c(accent3, other.accent3),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      glass: c(glass, other.glass),
      shadow: c(shadow, other.shadow),
    );
  }
}

// ---------------------------------------------------------------------------
// Raio, sombra, movimento, breakpoints
// ---------------------------------------------------------------------------

abstract final class AtlasRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AtlasShadows {
  /// Repouso: cards e painéis.
  static List<BoxShadow> soft(AtlasColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: c.dark ? 0.28 : 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: c.shadow.withValues(alpha: c.dark ? 0.32 : 0.07),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 10),
    ),
  ];

  /// Hover / elementos flutuantes (dropdowns, toasts).
  static List<BoxShadow> raised(AtlasColors c) => [
    BoxShadow(
      color: c.shadow.withValues(alpha: c.dark ? 0.35 : 0.07),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: c.shadow.withValues(alpha: c.dark ? 0.45 : 0.14),
      blurRadius: 40,
      spreadRadius: -8,
      offset: const Offset(0, 20),
    ),
  ];

  /// Halo colorido para botões de ação e elementos selecionados.
  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.32 * strength),
      blurRadius: 18 * strength,
      spreadRadius: -4,
      offset: Offset(0, 8 * strength),
    ),
  ];
}

/// Iluminação global simulada. A luz vem de cima-esquerda; todos os widgets
/// "3D" (logo, botões, ícones, cards com tilt) usam estes helpers para que
/// realces e sombras concordem entre si — é isso que vende a profundidade.
abstract final class AtlasLight {
  /// Clareia (amount > 0) ou escurece (amount < 0) uma cor.
  static Color shade(Color c, double amount) => amount >= 0
      ? Color.lerp(c, Colors.white, amount)!
      : Color.lerp(c, Colors.black, -amount)!;

  /// Volume de uma superfície colorida: face iluminada em cima-esquerda,
  /// sombra própria em baixo-direita.
  static LinearGradient volume(Color base, {double depth = 1}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [shade(base, 0.16 * depth), base, shade(base, -0.22 * depth)],
        stops: const [0, 0.5, 1],
      );

  /// Reflexo especular no topo (plástico/vidro). Sobreponha à face.
  static LinearGradient sheen({double strength = 1, bool dark = false}) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (dark ? 0.16 : 0.34) * strength),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.55],
      );

  /// Cor da "borda" (lateral extrudada) de um objeto de cor [base].
  static Color edge(Color base) => shade(base, -0.38);

  /// Sombras em camadas para uma elevação 0..1: sombra de contato curta e
  /// nítida + sombra ambiente longa e difusa, ambas tingidas por [tint].
  static List<BoxShadow> elevation(
    Color tint,
    double level, {
    bool dark = false,
  }) {
    final e = level.clamp(0.0, 1.0);
    return [
      BoxShadow(
        color: tint.withValues(alpha: (dark ? 0.45 : 0.12) + 0.06 * e),
        blurRadius: 2 + 4 * e,
        offset: Offset(0, 1 + 2 * e),
      ),
      BoxShadow(
        color: tint.withValues(alpha: (dark ? 0.35 : 0.10) + 0.14 * e),
        blurRadius: 12 + 36 * e,
        spreadRadius: -4 - 6 * e,
        offset: Offset(0, 6 + 20 * e),
      ),
    ];
  }
}

abstract final class AtlasMotion {
  static const instant = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);
  static const entrance = Duration(milliseconds: 460);

  /// Material 3 "emphasized decelerate" — entradas.
  static const enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Saídas rápidas.
  static const exit = Cubic(0.3, 0, 0.8, 0.15);

  /// Mudanças de estado padrão.
  static const standard = Cubic(0.2, 0, 0, 1);

  /// Pequeno overshoot para "pop" de feedback.
  static const pop = Curves.easeOutBack;

  /// Duração respeitando prefers-reduced-motion.
  static Duration of(BuildContext context, Duration d) =>
      context.reduceMotion ? Duration.zero : d;
}

abstract final class AtlasBreakpoints {
  static const double phone = 600;
  static const double tablet = 940;
  static const double desktop = 1100;
  static const double contentMax = 1480;
}

extension AtlasContext on BuildContext {
  AtlasColors get ac {
    final theme = Theme.of(this);
    return theme.extension<AtlasColors>() ??
        (theme.brightness == Brightness.dark
            ? AtlasColors.darkPalette
            : AtlasColors.lightPalette);
  }

  /// Usuário pediu menos movimento (prefers-reduced-motion).
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

ThemeData buildTheme({required bool dark, bool webFonts = true}) {
  final c = dark ? AtlasColors.darkPalette : AtlasColors.lightPalette;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    // Transparente: o AtlasBackdrop (gradiente ambiente) fica atrás de tudo.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: c.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent2,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.accent,
      surface: c.card,
    ),
    dividerColor: c.border,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: c.accent2.withValues(alpha: 0.06),
    focusColor: c.accent2.withValues(alpha: 0.12),
    highlightColor: c.accent2.withValues(alpha: 0.06),
    visualDensity: VisualDensity.standard,
  );
  final text = webFonts
      ? GoogleFonts.interTextTheme(base.textTheme)
      : base.textTheme;
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AtlasRadius.sm),
  );

  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    extensions: [c],
    textTheme: text
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          headlineSmall: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: c.text,
          ),
          titleLarge: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: c.text,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.glass,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        color: c.text,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        side: BorderSide(color: c.border),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accent2.withValues(alpha: 0.12),
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
      ),
      labelStyle: TextStyle(color: c.text, fontWeight: FontWeight.w600),
      checkmarkColor: c.accent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent2,
        foregroundColor: Colors.white,
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        elevation: 0,
        animationDuration: AtlasMotion.fast,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: AtlasMotion.fast,
        foregroundColor: WidgetStatePropertyAll(c.text),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? c.accent2.withValues(alpha: 0.06)
              : c.surface.withValues(alpha: 0.6),
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.hovered) ||
                    s.contains(WidgetState.focused)
                ? c.accent2.withValues(alpha: 0.55)
                : c.border,
          ),
        ),
        shape: WidgetStatePropertyAll(rounded),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        shape: rounded,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        animationDuration: AtlasMotion.fast,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: AtlasMotion.fast,
        shape: WidgetStatePropertyAll(rounded),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed)
              ? c.accent2.withValues(alpha: 0.14)
              : s.contains(WidgetState.hovered)
              ? c.accent2.withValues(alpha: 0.08)
              : null,
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: rounded,
      iconColor: c.muted,
      selectedColor: c.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface.withValues(alpha: dark ? 0.6 : 0.85),
      hoverColor: c.accent2.withValues(alpha: 0.03),
      hintStyle: TextStyle(color: c.muted),
      prefixIconColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.focused) ? c.accent : c.muted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: field(c.border),
      enabledBorder: field(c.border),
      focusedBorder: field(c.accent2, 1.6),
      errorBorder: field(c.danger),
      focusedErrorBorder: field(c.danger, 1.6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
      ),
    ),
    // Dropdowns e menus: cantos suaves e sombra elevada.
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: c.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.md),
        side: BorderSide(color: c.border),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasRadius.md),
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C3550) : const Color(0xFF0E1E33),
        borderRadius: BorderRadius.circular(AtlasRadius.xs),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: dark ? const Color(0xFF15304A) : const Color(0xFF0E1E33),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.glass,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accent2.withValues(alpha: 0.14),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.pill),
      ),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AtlasRadius.xl),
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent2,
      linearTrackColor: c.border,
      circularTrackColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent2 : c.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(c.muted.withValues(alpha: 0.35)),
      radius: const Radius.circular(AtlasRadius.pill),
      thickness: const WidgetStatePropertyAll(6),
    ),
    // Toda rota empurrada (Navigator.push / MaterialPageRoute) usa a mesma
    // transição de profundidade do app — ver AtlasPageTransitionsBuilder.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AtlasPageTransitionsBuilder(),
        TargetPlatform.iOS: AtlasPageTransitionsBuilder(),
        TargetPlatform.macOS: AtlasPageTransitionsBuilder(),
        TargetPlatform.windows: AtlasPageTransitionsBuilder(),
        TargetPlatform.linux: AtlasPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AtlasPageTransitionsBuilder(),
      },
    ),
  );
}
