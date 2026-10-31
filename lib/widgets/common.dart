/// Componentes visuais reutilizáveis: vidro, cards, skeleton, status, toasts.
///
/// As APIs públicas são as mesmas da versão anterior — só o visual e o
/// movimento mudaram — então as páginas não precisam ser reescritas.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'depth.dart';
import 'icon3d.dart';
import 'motion.dart';

export 'depth.dart';
export 'motion.dart';

/// Superfície de vidro: blur real do que está atrás + preenchimento
/// translúcido + borda com brilho. Use para barras, painéis e diálogos.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = AtlasRadius.lg,
    this.padding,
    this.blur = 18,
    this.opacity,
    this.highlight = false,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Sigma do desfoque. 0 desliga o BackdropFilter (mais barato).
  final double blur;

  /// Opacidade do preenchimento (padrão: [AtlasColors.glass]).
  final double? opacity;

  /// Adiciona uma lavagem de gradiente de marca (hero, banners).
  final bool highlight;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final shape = BorderRadius.circular(radius);
    final fill = opacity == null
        ? ac.glass
        : ac.surface.withValues(alpha: opacity!);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        color: fill,
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ac.accent2.withValues(alpha: ac.dark ? 0.22 : 0.10),
                  fill,
                  ac.accent3.withValues(alpha: ac.dark ? 0.16 : 0.07),
                ],
                stops: const [0, 0.55, 1],
              )
            : null,
        border: Border.all(
          color: ac.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      child: DecoratedBox(
        // Hairline externa para separar do fundo no tema claro.
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: ac.border.withValues(alpha: 0.65)),
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );

    if (blur > 0) {
      surface = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadow ? AtlasShadows.soft(ac) : null,
      ),
      child: ClipRRect(borderRadius: shape, child: surface),
    );
  }
}

/// Card de conteúdo com profundidade e micro-interações:
/// hover → borda tingida + sombra elevada (+ leve subida se clicável);
/// press → escala 0,985.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final interactive = widget.onTap != null;
    final accent = widget.accent ?? ac.accent2;
    final lift = _hover && interactive && !context.reduceMotion;
    final shape = BorderRadius.circular(AtlasRadius.md);

    Widget card = AnimatedContainer(
      duration: AtlasMotion.of(context, AtlasMotion.base),
      curve: AtlasMotion.standard,
      transform: Matrix4.translationValues(0, lift ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: ac.card.withValues(alpha: ac.dark ? 0.88 : 0.94),
        borderRadius: shape,
        border: Border.all(
          color: _hover ? accent.withValues(alpha: 0.38) : ac.border,
        ),
        boxShadow: _hover ? AtlasShadows.raised(ac) : AtlasShadows.soft(ac),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: accent.withValues(alpha: 0.05),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (interactive) card = PressScale(pressedScale: 0.985, child: card);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: card,
    );
  }
}

/// Bloco de carregamento com brilho deslizante (shimmer).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final base = ac.border.withValues(alpha: ac.dark ? 0.55 : 0.6);
    final shine = ac.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.9);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final x = -1.6 + 3.2 * _c.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius.clamp(4, 16)),
            gradient: LinearGradient(
              begin: Alignment(x - 0.6, -0.2),
              end: Alignment(x + 0.6, 0.2),
              colors: [base, Color.alphaBlend(shine, base), base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Esqueleto de página inteira (hero + KPIs + gráfico + lista), responsivo.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final kpis = w > 1050
            ? 4
            : w > 600
            ? 2
            : 1;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(w < 600 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 112, radius: 18),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < kpis; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    const Expanded(child: Skeleton(height: 104, radius: 14)),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              const Skeleton(height: 240, radius: 14),
              const SizedBox(height: 14),
              for (var i = 0; i < 3; i++) ...[
                const Skeleton(height: 64, radius: 14),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

Color statusColor(AtlasColors ac, OrderStatus s) => switch (s) {
  OrderStatus.pendente => ac.warning,
  OrderStatus.emTransito => ac.accent,
  OrderStatus.entregue => ac.success,
  OrderStatus.cancelado => ac.danger,
};

/// Pílula de status. Ao mudar de status (CRUD) faz crossfade + pop.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.late = false});

  final OrderStatus status;
  final bool late;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final color = late ? ac.danger : statusColor(ac, status);
    final label = late ? 'Atrasado' : status.label;
    final live = status == OrderStatus.emTransito && !late;
    return AnimatedSwitcher(
      duration: AtlasMotion.of(context, AtlasMotion.base),
      switchInCurve: AtlasMotion.pop,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey('$status-$late'),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: ac.dark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(AtlasRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: live
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio com ícone em halo e entrada suave.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return FadeSlideIn(
      scale: 0.96,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ac.accent2.withValues(alpha: 0.18),
                        ac.accent2.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon3D(
                      icon: Icons.inventory_2_rounded,
                      color: ac.accent2,
                      motion: IconMotion.bounce,
                      size: 60,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ac.muted, height: 1.45),
                ),
                if (action != null) ...[const SizedBox(height: 20), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contador numérico de KPI. Anima do valor anterior ao novo (não de 0)
/// quando o dado muda depois de uma ação de CRUD.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AtlasMotion.of(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(
        '${v.round()}',
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Cartão de KPI com ícone em ladrilho colorido e contador animado.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.motion,
    this.loop = false,
    this.hint,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final IconMotion motion;
  final bool loop;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    // KPIs clicáveis inclinam na direção do ponteiro (profundidade = "dá
    // para clicar"); KPIs informativos ficam planos.
    return Tilt3D(
      enabled: onTap != null,
      maxTilt: 0.12,
      child: GlassCard(
      onTap: onTap,
      accent: color,
      child: Row(
        children: [
          Icon3D(
            icon: icon,
            color: color,
            motion: motion,
            loop: loop,
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(
                  value: value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ac.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: ac.muted.withValues(alpha: 0.6),
            ),
        ],
      ),
      ),
    );
  }
}

/// Moldura padrão de diálogos: vidro, cabeçalho fixo, corpo rolável e
/// barra de ações. A animação de entrada/saída vem de [showAtlasDialog].
class DialogShell extends StatelessWidget {
  const DialogShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = 560,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final phone = MediaQuery.sizeOf(context).width < AtlasBreakpoints.phone;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(phone ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AtlasRadius.xl),
            boxShadow: AtlasShadows.raised(ac),
          ),
          child: Glass(
            opacity: ac.dark ? 0.9 : 0.94,
            radius: AtlasRadius.xl,
            blur: 24,
            shadow: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 10, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: ac.brandGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.close_rounded, color: ac.muted),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: ac.border.withValues(alpha: 0.7)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                    child: child,
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toast flutuante (snackbar) com ícone que "salta" ao aparecer.
/// Em telas largas fica com largura fixa e centralizado.
void toast(BuildContext context, String message, {bool error = false}) {
  final ac = context.ac;
  final color = error ? ac.danger : ac.success;
  final wide = MediaQuery.sizeOf(context).width >= AtlasBreakpoints.phone;
  final reduce = context.reduceMotion;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        width: wide ? 440 : null,
        duration: Duration(seconds: error ? 5 : 3),
        content: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: reduce ? 1.0 : 0.4, end: 1.0),
              duration: reduce ? Duration.zero : AtlasMotion.slow,
              curve: AtlasMotion.pop,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                ),
                child: Icon(
                  error ? Icons.error_rounded : Icons.check_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Título de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 560;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: small ? 21 : 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: ac.muted, height: 1.4)),
            ],
          ],
        );
        if (trailing == null) return heading;
        if (small) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: trailing!),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            trailing!,
          ],
        );
      },
    );
  }
}
