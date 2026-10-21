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
    final aPath = Path()
      ..moveTo(offset.dx + 15 * scale, offset.dy + 84 * scale)
      ..lineTo(offset.dx + 43 * scale, offset.dy + 19 * scale)
      ..quadraticBezierTo(
        offset.dx + 50 * scale,
        offset.dy + 8 * scale,
        offset.dx + 57 * scale,
        offset.dy + 19 * scale,
      )
      ..lineTo(offset.dx + 85 * scale, offset.dy + 84 * scale);
    final crossbar = Path()
      ..moveTo(offset.dx + 30 * scale, offset.dy + 60 * scale)
      ..lineTo(offset.dx + 70 * scale, offset.dy + 60 * scale);
    final arrow = Path()
      ..moveTo(offset.dx + 13 * scale, offset.dy + 68 * scale)
      ..lineTo(offset.dx + 42 * scale, offset.dy + 61 * scale)
      ..lineTo(offset.dx + 70 * scale, offset.dy + 34 * scale);
    final arrowHead = Path()
      ..moveTo(offset.dx + 61 * scale, offset.dy + 32 * scale)
      ..lineTo(offset.dx + 73 * scale, offset.dy + 30 * scale)
      ..lineTo(offset.dx + 72 * scale, offset.dy + 43 * scale);

    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFD5F7FF), Color(0xFF82D9F0)],
      ).createShader(bounds);
    final darkExtrusion = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = blue.withValues(alpha: 0.65);

    canvas.save();
    canvas.translate(0, 2 * scale);
    canvas.drawPath(aPath, darkExtrusion);
    canvas.drawPath(crossbar, darkExtrusion);
    canvas.restore();
    canvas.drawPath(aPath, metal);
    canvas.drawPath(crossbar, metal);

    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = cyan
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale);
    canvas.drawPath(arrow, arrowPaint);
    canvas.drawPath(arrowHead, arrowPaint..maskFilter = null);
    final arrowFace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = highlight;
    canvas.drawPath(arrow, arrowFace);
    canvas.drawPath(arrowHead, arrowFace);
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.highlight != highlight;
}
