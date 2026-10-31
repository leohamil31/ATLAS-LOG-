import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'depth.dart';

/// Marca ATLAS em "3D" desenhada em Canvas (sem assets, nítida em qualquer
/// tamanho):
/// * extrusão — a forma é repetida em camadas deslocadas para baixo-direita,
///   escurecendo, como a lateral de uma peça sólida;
/// * face frontal iluminada por gradiente (luz de cima-esquerda, AtlasLight);
/// * faixa de brilho que varre a peça ao aparecer e no hover;
/// * inclinação pelo ponteiro (Tilt3D) a partir de 56 px.
class AtlasLogo3D extends StatefulWidget {
  const AtlasLogo3D({
    super.key,
    this.size = 44,
    this.showWordmark = false,
    this.extrude = true,
    this.interactive = true,
  });

  final double size;
  final bool showWordmark;

  /// Desenha as camadas de extrusão (desligue em tamanhos muito pequenos).
  final bool extrude;

  /// Tilt pelo ponteiro + brilho no hover.
  final bool interactive;

  @override
  State<AtlasLogo3D> createState() => _AtlasLogo3DState();
}

class _AtlasLogo3DState extends State<AtlasLogo3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || context.reduceMotion) return;
    _started = true;
    _sheen.forward(from: 0);
  }

  void _replay() {
    if (!widget.interactive || context.reduceMotion || _sheen.isAnimating) {
      return;
    }
    _sheen.forward(from: 0);
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    Widget mark = MouseRegion(
      onEnter: (_) => _replay(),
      child: Semantics(
        label: 'Logo ATLAS LOG',
        image: true,
        child: SizedBox.square(
          dimension: widget.size,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AtlasMarkPainter(
                primary: colors.text,
                accent: colors.accent2,
                accent2: colors.accent3,
                dark: colors.dark,
                extrude: widget.extrude && widget.size >= 28,
                sheen: _sheen,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.interactive && widget.size >= 56) {
      mark = Tilt3D(
        maxTilt: 0.22,
        hoverScale: 1.04,
        glare: false,
        child: mark,
      );
    }

    if (!widget.showWordmark) return mark;
    final size = widget.size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATLAS LOG',
              style: TextStyle(
                color: colors.text,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
            Text(
              'GESTÃO LOGÍSTICA',
              style: TextStyle(
                color: colors.muted,
                fontSize: size * 0.16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AtlasMarkPainter extends CustomPainter {
  _AtlasMarkPainter({
    required this.primary,
    required this.accent,
    required this.accent2,
    required this.dark,
    required this.extrude,
    required this.sheen,
  }) : super(repaint: sheen);

  final Color primary;
  final Color accent;
  final Color accent2;
  final bool dark;
  final bool extrude;
  final Animation<double> sheen;

  /// Monta as duas peças da marca (corpo "A" e seta) no quadrado [size].
  (Path body, Path arrow) _paths(Size size) {
    final unit = size.shortestSide;
    final offset = Offset((size.width - unit) / 2, (size.height - unit) / 2);
    final scale = unit / 100;
    Offset p(double x, double y) =>
        Offset(offset.dx + x * scale, offset.dy + y * scale);

    final leftLeg = Path()
      ..moveTo(p(12, 90).dx, p(12, 90).dy)
      ..lineTo(p(36, 15).dx, p(36, 15).dy)
      ..lineTo(p(55, 15).dx, p(55, 15).dy)
      ..lineTo(p(73, 57).dx, p(73, 57).dy)
      ..lineTo(p(57, 67).dx, p(57, 67).dy)
      ..lineTo(p(46, 43).dx, p(46, 43).dy)
      ..lineTo(p(30, 90).dx, p(30, 90).dy)
      ..close();
    final rightLeg = Path()
      ..moveTo(p(57, 67).dx, p(57, 67).dy)
      ..lineTo(p(73, 57).dx, p(73, 57).dy)
      ..lineTo(p(91, 90).dx, p(91, 90).dy)
      ..lineTo(p(71, 90).dx, p(71, 90).dy)
      ..close();
    final body = Path()
      ..addPath(leftLeg, Offset.zero)
      ..addPath(rightLeg, Offset.zero);

    final arrow = Path()
      ..moveTo(p(7, 77).dx, p(7, 77).dy)
      ..cubicTo(
        p(31, 77).dx,
        p(31, 77).dy,
        p(51, 68).dx,
        p(51, 68).dy,
        p(69, 49).dx,
        p(69, 49).dy,
      )
      ..lineTo(p(82, 34).dx, p(82, 34).dy)
      ..lineTo(p(75, 30).dx, p(75, 30).dy)
      ..lineTo(p(96, 18).dx, p(96, 18).dy)
      ..lineTo(p(92, 43).dx, p(92, 43).dy)
      ..lineTo(p(87, 38).dx, p(87, 38).dy)
      ..lineTo(p(74, 54).dx, p(74, 54).dy)
      ..cubicTo(
        p(54, 74).dx,
        p(54, 74).dy,
        p(31, 84).dx,
        p(31, 84).dy,
        p(7, 84).dx,
        p(7, 84).dy,
      )
      ..close();
    return (body, arrow);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (body, arrow) = _paths(size);
    final rect = Offset.zero & size;

    // 1. Extrusão: camadas deslocadas na direção oposta à luz.
    if (extrude) {
      final layers = math.max(3, (size.shortestSide * 0.07).round());
      final step = size.shortestSide * 0.012;
      final bodySide = AtlasLight.edge(primary);
      final arrowSide = AtlasLight.edge(accent);
      for (var i = layers; i >= 1; i--) {
        final t = i / layers;
        final o = Offset(step * i * 0.7, step * i);
        canvas
          ..drawPath(
            body.shift(o),
            Paint()..color = AtlasLight.shade(bodySide, -0.25 * t),
          )
          ..drawPath(
            arrow.shift(o),
            Paint()..color = AtlasLight.shade(arrowSide, -0.25 * t),
          );
      }
    }

    // 2. Faces frontais com gradiente de iluminação.
    canvas
      ..drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [Colors.white, AtlasLight.shade(primary, -0.18)]
                : [AtlasLight.shade(primary, 0.28), primary],
          ).createShader(rect),
      )
      ..drawPath(
        arrow,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [accent, accent2],
          ).createShader(rect),
      );

    // 3. Varredura de brilho, recortada ao formato da marca.
    final t = sheen.value;
    if (t > 0 && t < 1) {
      final x = -0.6 + 2.2 * Curves.easeInOut.transform(t);
      canvas
        ..save()
        ..clipPath(
          Path()
            ..addPath(body, Offset.zero)
            ..addPath(arrow, Offset.zero),
        )
        ..drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment(-1 + x * 2 - 0.5, -1),
              end: Alignment(-1 + x * 2 + 0.5, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(rect),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter old) =>
      old.primary != primary ||
      old.accent != accent ||
      old.accent2 != accent2 ||
      old.dark != dark ||
      old.extrude != extrude;
}
