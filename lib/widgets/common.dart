/// Componentes visuais reutilizáveis: vidro, cards, skeleton, chips, etc.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'icon3d.dart';

/// Painel translúcido com blur (glassmorphism).
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.blur = 18,
    this.opacity,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            color: (ac.dark ? ac.card : Colors.white).withValues(
              alpha: opacity ?? (ac.dark ? 0.62 : 0.78),
            ),
            border: Border.all(color: ac.border.withValues(alpha: 0.8)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Card sólido com hover suave.
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
    final dur = context.reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: dur,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover && widget.onTap != null ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: ac.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hover ? (widget.accent ?? ac.accent).withValues(alpha: 0.6) : ac.border,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hover ? (widget.accent ?? ac.accent) : Colors.black)
                  .withValues(alpha: _hover ? 0.18 : (ac.dark ? 0.25 : 0.06)),
              blurRadius: _hover ? 22 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Bloco cinza pulsante para estados de carregamento.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(
            ac.border.withValues(alpha: 0.45),
            ac.border.withValues(alpha: 0.9),
            _c.value,
          ),
        ),
      ),
    );
  }
}

/// Esqueleto de página inteira (cards + lista).
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 28, width: 220),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                const Expanded(child: Skeleton(height: 110, radius: 20)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Skeleton(height: 240, radius: 20),
          const SizedBox(height: 14),
          const Skeleton(height: 60, radius: 16),
        ],
      ),
    );
  }
}

Color statusColor(AtlasColors ac, OrderStatus s) => switch (s) {
  OrderStatus.pendente => ac.warning,
  OrderStatus.emTransito => ac.accent,
  OrderStatus.entregue => ac.success,
  OrderStatus.cancelado => ac.danger,
};

/// Chip de status; "Em Trânsito" ganha um ponto pulsando.
class StatusChip extends StatefulWidget {
  const StatusChip({super.key, required this.status, this.late = false});

  final OrderStatus status;
  final bool late;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pulse = widget.status == OrderStatus.emTransito && !context.reduceMotion;
    if (pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!pulse) {
      _c.stop();
    }
  }

  @override
  void didUpdateWidget(covariant StatusChip old) {
    super.didUpdateWidget(old);
    didChangeDependencies();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final color = widget.late ? ac.danger : statusColor(ac, widget.status);
    final label = widget.late ? 'Atrasado' : widget.status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 3 + 6 * _c.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon3D(
              icon: Icons.inventory_2_rounded,
              color: ac.accent2,
              motion: IconMotion.bounce,
              size: 56,
              loop: true,
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: ac.muted)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Contador numérico que anima de 0 até o valor.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final dur = context.reduceMotion ? Duration.zero : const Duration(milliseconds: 700);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: dur,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Cartão de KPI com ícone 3D animado.
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
    return GlassCard(
      onTap: onTap,
      accent: color,
      child: Row(
        children: [
          Icon3D(icon: icon, color: color, motion: motion, loop: loop, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(
                  value: value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ac.muted, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (hint != null)
                  Text(hint!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Moldura padrão de diálogos (vidro, largura limitada, rolável).
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Glass(
          opacity: ac.dark ? 0.92 : 0.96,
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 10, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close_rounded, color: ac.muted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
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
    );
  }
}

void toast(BuildContext context, String message, {bool error = false}) {
  final ac = context.ac;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_rounded : Icons.check_circle_rounded,
              color: error ? ac.danger : ac.success,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Título de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: ac.muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
