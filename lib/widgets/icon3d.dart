/// Ícone com animação sutil, sem azulejo, brilho plástico ou sombra pesada.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum IconMotion { spin, drive, tilt, pulse, pop, bounce }

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
  });

  final IconData icon;
  final Color color;
  final IconMotion motion;
  final double size;

  /// Dispara a animação (ex.: item de menu com mouse em cima).
  final bool animate;

  /// Mantém a animação em loop suave (ex.: "Em Trânsito").
  final bool loop;

  /// Versão apagada (etapas futuras).
  final bool muted;

  @override
  State<Icon3D> createState() => _Icon3DState();
}

class _Icon3DState extends State<Icon3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _hover = false;
  bool _reduce = false;

  bool get _active => (widget.animate || _hover || widget.loop) && !_reduce;

  void _sync() {
    if (!_active) {
      if (_c.isAnimating || _c.value != 0) {
        _c.animateTo(0, duration: const Duration(milliseconds: 250));
      }
      return;
    }
    if (widget.loop) {
      if (!_c.isAnimating || _c.status != AnimationStatus.forward) {
        _c.repeat();
      }
    } else if (!_c.isAnimating) {
      _c.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = context.reduceMotion;
    _sync();
  }

  @override
  void didUpdateWidget(covariant Icon3D old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _glyph(double t, Color glyphColor) {
    final s = widget.size * 0.62;
    Widget g = Icon(widget.icon, size: s, color: glyphColor);
    final w = math.sin(t * math.pi * 2);
    switch (widget.motion) {
      case IconMotion.spin:
        g = Transform.rotate(angle: t * math.pi * 2, child: g);
      case IconMotion.drive:
        g = Transform.translate(
          offset: Offset(w * widget.size * 0.1, -w.abs() * 1.5),
          child: g,
        );
      case IconMotion.tilt:
        g = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.01)
            ..rotateY(w * 0.7)
            ..rotateX(w * 0.15),
          child: g,
        );
      case IconMotion.pulse:
        g = Transform.scale(scale: 1 + 0.16 * (0.5 + 0.5 * w), child: g);
      case IconMotion.pop:
        final p = Curves.elasticOut.transform(math.min(1, t * 1.6));
        g = Transform.scale(scale: t == 0 ? 1 : 0.7 + 0.3 * p, child: g);
      case IconMotion.bounce:
        g = Transform.translate(offset: Offset(0, -w.abs() * 3), child: g);
    }
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final glyphColor = widget.muted ? context.ac.muted : widget.color;

    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        _sync();
      },
      onExit: (_) {
        _hover = false;
        _sync();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(child: _glyph(_c.value, glyphColor)),
        ),
      ),
    );
  }
}
