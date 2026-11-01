import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum IconMotion { spin, drive, tilt, pulse, pop, bounce }

/// Ícone com ladrilho de VIDRO FOSCO (a partir de 40 px) e micro-movimento.
///
/// Vidro (padrão, `glass: true`): desfoque do fundo + branco translúcido
/// tingido pela cor do ícone + borda clara + reflexo no topo + luz de borda
/// embaixo — o equivalente Flutter do "Liquid Glass" (expo-glass-effect).
///
/// Iluminação: gradiente de volume + reflexo especular no topo + sombra
/// colorida que cresce no hover (o ladrilho "sobe" 2 px).
///
/// * `loop`    → movimento contínuo e sutil (ex.: caminhão "rodando");
/// * `animate` → toca o movimento uma vez ao aparecer;
/// * hover     → toca o movimento uma vez (desktop/web).
///
/// Tudo é desligado quando o sistema pede movimento reduzido.
class Icon3D extends StatefulWidget {
  const Icon3D({
    super.key,
    required this.icon,
    required this.color,
    this.motion = IconMotion.tilt,
    this.size = 40,
    this.animate = false,
    this.loop = false,
    this.muted = false,
    this.glass = true,
  });

  final IconData icon;
  final Color color;
  final IconMotion motion;
  final double size;
  final bool animate;
  final bool loop;
  final bool muted;

  /// Ladrilho de vidro fosco (blur + translucidez + reflexo). Desligue em
  /// listas muito longas: cada ladrilho de vidro custa um BackdropFilter.
  final bool glass;

  @override
  State<Icon3D> createState() => _Icon3DState();
}

class _Icon3DState extends State<Icon3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;
  bool _hover = false;

  bool get _reduce => context.reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce) {
      _c
        ..stop()
        ..value = 0;
      return;
    }
    if (!_started) {
      _started = true;
      if (widget.loop) {
        _c.repeat(reverse: true);
      } else if (widget.animate) {
        _playOnce();
      }
    }
  }

  @override
  void didUpdateWidget(Icon3D old) {
    super.didUpdateWidget(old);
    if (old.loop == widget.loop || _reduce) return;
    if (widget.loop) {
      _c.repeat(reverse: true);
    } else {
      _c.animateTo(0, duration: AtlasMotion.base);
    }
  }

  void _playOnce() {
    if (_reduce || widget.loop || _c.isAnimating) return;
    _c.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && !widget.loop) _c.reverse();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _move(double t, Widget child) {
    final s = widget.size;
    return switch (widget.motion) {
      IconMotion.drive => Transform.translate(
        offset: Offset(s * 0.04 * (t * 2 - 1), 0),
        child: child,
      ),
      IconMotion.tilt => Transform.rotate(angle: 0.12 * (t - 0.5), child: child),
      IconMotion.spin => Transform.rotate(angle: t * 3.14159, child: child),
      IconMotion.pulse => Transform.scale(scale: 1 + 0.08 * t, child: child),
      IconMotion.pop => Transform.scale(scale: 1 + 0.12 * t, child: child),
      IconMotion.bounce => Transform.translate(
        offset: Offset(0, -s * 0.05 * t),
        child: child,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final iconColor = widget.muted ? ac.muted : widget.color;
    final tiled = widget.size >= 40 && !widget.muted;
    final s = widget.size;
    final glyph = Icon(
      widget.icon,
      size: s * (tiled ? 0.5 : 0.62),
      color: iconColor,
      // Sombra curta do próprio glifo: dá relevo sobre o ladrilho.
      shadows: tiled
          ? [
              Shadow(
                color: AtlasLight.shade(
                  iconColor,
                  -0.5,
                ).withValues(alpha: ac.dark ? 0.6 : 0.35),
                blurRadius: s * 0.06,
                offset: Offset(0, s * 0.03),
              ),
            ]
          : null,
    );

    final animated = AnimatedBuilder(
      animation: _c,
      child: glyph,
      builder: (_, child) =>
          _move(Curves.easeInOut.transform(_c.value), child!),
    );

    if (!tiled) {
      return MouseRegion(
        onEnter: (_) => _playOnce(),
        child: SizedBox.square(dimension: s, child: Center(child: animated)),
      );
    }

    final radius = BorderRadius.circular(s * 0.3);
    final lift = _hover && !_reduce;
    final dark = ac.dark;
    final glass = widget.glass;

    // Corpo do ladrilho.
    // * vidro: branco translúcido levemente tingido pela cor do ícone, sobre
    //   o desfoque do que está atrás (BackdropFilter);
    // * sólido: volume tingido (comportamento anterior).
    final body = BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: glass
            ? [
                Color.alphaBlend(
                  iconColor.withValues(alpha: dark ? 0.22 : 0.12),
                  Colors.white.withValues(alpha: dark ? 0.12 : 0.62),
                ),
                Color.alphaBlend(
                  iconColor.withValues(alpha: dark ? 0.12 : 0.08),
                  Colors.white.withValues(alpha: dark ? 0.04 : 0.28),
                ),
              ]
            : [
                iconColor.withValues(alpha: dark ? 0.34 : 0.20),
                iconColor.withValues(alpha: dark ? 0.14 : 0.07),
              ],
      ),
      border: Border.all(
        color: glass
            ? Colors.white.withValues(alpha: dark ? 0.18 : 0.75)
            : iconColor.withValues(alpha: dark ? 0.32 : 0.18),
      ),
    );

    Widget tile = DecoratedBox(
      decoration: body,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Reflexo especular: elipse clara na metade superior.
          Positioned(
            left: s * 0.08,
            right: s * 0.08,
            top: s * 0.05,
            height: s * 0.42,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(s * 0.24),
                    bottom: Radius.circular(s * 0.4),
                  ),
                  gradient: AtlasLight.sheen(
                    strength: glass ? 1.2 : 0.9,
                    dark: dark,
                  ),
                ),
              ),
            ),
          ),
          // Luz de borda inferior (refração do vidro), só no modo vidro.
          if (glass)
            Positioned(
              left: s * 0.18,
              right: s * 0.18,
              bottom: s * 0.04,
              height: s * 0.18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s * 0.2),
                    gradient: RadialGradient(
                      colors: [
                        iconColor.withValues(alpha: dark ? 0.45 : 0.30),
                        iconColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Center(child: animated),
        ],
      ),
    );

    if (glass) {
      tile = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: tile,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        _playOnce();
      },
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: AtlasMotion.of(context, AtlasMotion.base),
        curve: AtlasMotion.standard,
        width: s,
        height: s,
        transform: Matrix4.translationValues(0, lift ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: lift ? 0.34 : 0.18),
              blurRadius: lift ? s * 0.42 : s * 0.24,
              spreadRadius: -s * 0.08,
              offset: Offset(0, lift ? s * 0.16 : s * 0.1),
            ),
          ],
        ),
        child: tile,
      ),
    );
  }
}
