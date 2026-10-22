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
            final glow = _hovered ? 0.34 : 0.16 + float * 0.04;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0025)
                ..rotateY(turn * 0.08)
                ..rotateZ(math.sin(float * math.pi * 2) * 0.018)
                ..translateByDouble(
                  0.0,
                  math.sin(float * math.pi * 2) * -1.2,
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
                      blurRadius: _hovered ? 18 : 10,
                      spreadRadius: 0,
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
    Path shifted(Path path, double dy) => path.transform(
      (Matrix4.identity()..translateByDouble(0, dy * scale, 0, 1)).storage,
    );

    final leftLeg = Path()
      ..moveTo(point(10, 88).dx, point(10, 88).dy)
      ..lineTo(point(35, 20).dx, point(35, 20).dy)
      ..lineTo(point(58, 20).dx, point(58, 20).dy)
      ..lineTo(point(76, 54).dx, point(76, 54).dy)
      ..lineTo(point(60, 62).dx, point(60, 62).dy)
      ..lineTo(point(51, 39).dx, point(51, 39).dy)
      ..lineTo(point(45, 39).dx, point(45, 39).dy)
      ..lineTo(point(27, 88).dx, point(27, 88).dy)
      ..close();
    final rightLeg = Path()
      ..moveTo(point(60, 62).dx, point(60, 62).dy)
      ..lineTo(point(76, 54).dx, point(76, 54).dy)
      ..lineTo(point(92, 88).dx, point(92, 88).dy)
      ..lineTo(point(73, 88).dx, point(73, 88).dy)
      ..close();
    final metal = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          highlight,
          const Color(0xFFC7DCE8),
          const Color(0xFF7895A8),
        ],
        stops: const [0, 0.28, 0.7, 1],
      ).createShader(bounds);
    final extrusion = Paint()
      ..style = PaintingStyle.fill
      ..color = blue.withValues(alpha: 0.78);
    for (var layer = 4; layer >= 1; layer--) {
      canvas.drawPath(shifted(leftLeg, layer * 0.7), extrusion);
      canvas.drawPath(shifted(rightLeg, layer * 0.7), extrusion);
    }
    canvas.drawShadow(leftLeg, blue.withValues(alpha: 0.28), 2.2 * scale, false);
    canvas.drawShadow(rightLeg, blue.withValues(alpha: 0.25), 2.2 * scale, false);
    canvas.drawPath(leftLeg, metal);
    canvas.drawPath(rightLeg, metal);

    final arrow = Path()
      ..moveTo(point(6, 77).dx, point(6, 77).dy)
      ..cubicTo(
        point(29, 76).dx,
        point(29, 76).dy,
        point(50, 66).dx,
        point(50, 66).dy,
        point(68, 49).dx,
        point(68, 49).dy,
      )
      ..lineTo(point(89, 26).dx, point(89, 26).dy);
    final arrowHead = Path()
      ..moveTo(point(76, 24).dx, point(76, 24).dy)
      ..lineTo(point(94, 16).dx, point(94, 16).dy)
      ..lineTo(point(91, 39).dx, point(91, 39).dy)
      ..close();
    final arrowBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = blue;
    canvas.drawPath(shifted(arrow, 2), arrowBase);
    canvas.drawPath(
      shifted(arrowHead, 2),
      Paint()
        ..style = PaintingStyle.fill
        ..color = blue,
    );
    canvas.drawPath(arrow, arrowBase..strokeWidth = 10.5 * scale..color = cyan);
    canvas.drawPath(arrowHead, Paint()..color = cyan);
    final arrowFace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.3 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          const Color(0xFFE4F2F8),
          const Color(0xFF9BB7C9),
        ],
      ).createShader(bounds);
    canvas.drawPath(arrow, arrowFace);
    canvas.drawPath(
      arrowHead,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFF9BB7C9)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * scale
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.highlight != highlight;
}
