/// Profundidade interativa: inclinação 3D guiada pelo ponteiro + reflexo.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Inclina o filho em perspectiva na direção do ponteiro (desktop/web) e
/// desenha um reflexo especular que segue o cursor.
///
/// * Só reage a mouse/trackpad: em toque fica estático (sem "pulos").
/// * Desligado quando o sistema pede movimento reduzido.
/// * Não altera layout nem hit-test do filho — pode envolver qualquer card.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxTilt = 0.10,
    this.hoverScale = 1.015,
    this.glare = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(AtlasRadius.md)),
    this.enabled = true,
  });

  final Widget child;

  /// Inclinação máxima em radianos (0,10 ≈ 6°).
  final double maxTilt;
  final double hoverScale;
  final bool glare;

  /// Recorte do reflexo — use o mesmo raio do card envolvido.
  final BorderRadius borderRadius;
  final bool enabled;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  /// Posição normalizada do ponteiro (-1..1 em cada eixo); zero = centro.
  Offset _pointer = Offset.zero;
  bool _hover = false;

  void _onHover(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    setState(() {
      _hover = true;
      _pointer = Offset(
        (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
        (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _onExit() => setState(() {
    _hover = false;
    _pointer = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || context.reduceMotion) return widget.child;
    final dark = context.ac.dark;

    return MouseRegion(
      onHover: (e) => _onHover(e.localPosition),
      onExit: (_) => _onExit(),
      child: TweenAnimationBuilder<Offset>(
        // O tween anima do valor atual até o novo alvo a cada movimento:
        // o card "persegue" o cursor com suavidade em vez de pular.
        tween: Tween(end: _pointer),
        duration: _hover ? AtlasMotion.fast : AtlasMotion.slow,
        curve: _hover ? Curves.easeOut : AtlasMotion.pop,
        child: widget.child,
        builder: (context, p, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspectiva
            ..rotateX(-p.dy * widget.maxTilt)
            ..rotateY(p.dx * widget.maxTilt);
          return AnimatedScale(
            scale: _hover ? widget.hoverScale : 1,
            duration: AtlasMotion.base,
            curve: AtlasMotion.standard,
            child: Transform(
              alignment: Alignment.center,
              transform: transform,
              child: !widget.glare
                  ? child
                  : Stack(
                      children: [
                        child!,
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _hover ? 1 : 0,
                              duration: AtlasMotion.base,
                              child: ClipRRect(
                                borderRadius: widget.borderRadius,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(p.dx, p.dy),
                                      radius: 1.1,
                                      colors: [
                                        Colors.white.withValues(
                                          alpha: dark ? 0.10 : 0.30,
                                        ),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
