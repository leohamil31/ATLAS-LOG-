import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class AtlasLogo3D extends StatefulWidget {
  const AtlasLogo3D({super.key, this.size = 44, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  State<AtlasLogo3D> createState() => _AtlasLogo3DState();
}

class _AtlasLogo3DState extends State<AtlasLogo3D>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  bool _hovered = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = context.reduceMotion;
    if (_reduceMotion) {
      _float
        ..stop()
        ..value = 0;
      _turn
        ..stop()
        ..value = 0;
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    if (_reduceMotion) return;
    if (value) {
      _turn.forward(from: 0);
    } else {
      _turn.reverse();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final duration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    final mark = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Semantics(
        label: 'Logo ATLAS-LOG, letra A com seta de crescimento',
        image: true,
        child: AnimatedBuilder(
          animation: Listenable.merge([_float, _turn]),
          builder: (context, _) {
            final float = _float.value;
            final turn = _turn.value;
            final glow = _hovered ? 0.75 : 0.28 + float * 0.12;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0025)
                ..rotateY(turn * math.pi * 2)
                ..rotateZ(math.sin(float * math.pi * 2) * 0.035)
                ..translateByDouble(
                  0.0,
                  math.sin(float * math.pi * 2) * -2.0,
                  0.0,
                  1.0,
                ),
              child: AnimatedContainer(
                duration: duration,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: glow),
                      blurRadius: _hovered ? 26 : 14,
                      spreadRadius: _hovered ? 2 : 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _AtlasMarkPainter(
                    cyan: colors.accent,
                    blue: colors.accent2,
                    highlight: const Color(0xFFE0FBFF),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 11),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: colors.text,
                  fontSize: widget.size * 0.34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                children: [
                  const TextSpan(text: 'ATLAS'),
                  TextSpan(
                    text: '-LOG',
                    style: TextStyle(color: colors.accent),
                  ),
                ],
              ),
            ),
            Text(
              'GESTÃO LOGÍSTICA',
              style: TextStyle(
                color: colors.muted,
                fontSize: widget.size * 0.18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AtlasMarkPainter extends CustomPainter {
  const _AtlasMarkPainter({
    required this.cyan,
    required this.blue,
    required this.highlight,
  });

  final Color cyan;
  final Color blue;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final offset = Offset((size.width - unit) / 2, (size.height - unit) / 2);
    final bounds = Rect.fromLTWH(offset.dx, offset.dy, unit, unit);
    final scale = unit / 100;
    Offset point(double x, double y) =>
        Offset(offset.dx + x * scale, offset.dy + y * scale);
    final leftLeg = Path()
      ..moveTo(point(10, 86).dx, point(10, 86).dy)
      ..lineTo(point(40, 18).dx, point(40, 18).dy)
      ..quadraticBezierTo(
        point(50, 4).dx,
        point(50, 4).dy,
        point(60, 18).dx,
        point(60, 18).dy,
      )
      ..lineTo(point(68, 37).dx, point(68, 37).dy)
      ..lineTo(point(55, 44).dx, point(55, 44).dy)
      ..lineTo(point(49, 30).dx, point(49, 30).dy)
      ..lineTo(point(25, 86).dx, point(25, 86).dy)
      ..close();
    final rightLeg = Path()
      ..moveTo(point(55, 50).dx, point(55, 50).dy)
      ..lineTo(point(68, 43).dx, point(68, 43).dy)
      ..lineTo(point(87, 86).dx, point(87, 86).dy)
      ..lineTo(point(70, 86).dx, point(70, 86).dy)
      ..close();
    final crossbar = Path()
      ..moveTo(point(31, 59).dx, point(31, 59).dy)
      ..lineTo(point(67, 59).dx, point(67, 59).dy)
      ..lineTo(point(74, 73).dx, point(74, 73).dy)
      ..lineTo(point(25, 73).dx, point(25, 73).dy)
      ..close();
    final arrow = Path()
      ..moveTo(point(8, 78).dx, point(8, 78).dy)
      ..cubicTo(
        point(29, 75).dx,
        point(29, 75).dy,
        point(52, 66).dx,
        point(52, 66).dy,
        point(72, 46).dx,
        point(72, 46).dy,
      )
      ..lineTo(point(88, 28).dx, point(88, 28).dy);
    final arrowHead = Path()
      ..moveTo(point(72, 30).dx, point(72, 30).dy)
      ..lineTo(point(92, 20).dx, point(92, 20).dy)
      ..lineTo(point(88, 42).dx, point(88, 42).dy);

    final metal = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFF4FDFF),
          Color(0xFFB7EAF5),
          Color(0xFF78C9E0),
        ],
      ).createShader(bounds);
    final darkExtrusion = Paint()
      ..style = PaintingStyle.fill
      ..color = blue.withValues(alpha: 0.72);

    canvas.save();
    canvas.translate(0, 3 * scale);
    canvas.drawPath(leftLeg, darkExtrusion);
    canvas.drawPath(rightLeg, darkExtrusion);
    canvas.drawPath(crossbar, darkExtrusion);
    canvas.restore();
    canvas.drawPath(leftLeg, metal);
    canvas.drawPath(rightLeg, metal);
    canvas.drawPath(crossbar, metal);

    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = cyan
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    canvas.drawPath(arrow, arrowPaint);
    canvas.drawPath(arrowHead, arrowPaint..strokeWidth = 7 * scale);
    final arrowFace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = highlight;
    canvas.drawPath(arrow, arrowFace);
    canvas.drawPath(arrowHead, arrowFace);

    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawPath(leftLeg, bevel);
    canvas.drawPath(rightLeg, bevel);
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.highlight != highlight;
}
