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
    Path mapPath(Path source, Offset shift) => source.transform(
      (Matrix4.identity()..translateByDouble(shift.dx, shift.dy, 0, 1)).storage,
    );

    final outerA = Path()
      ..moveTo(point(8, 89).dx, point(8, 89).dy)
      ..lineTo(point(38, 17).dx, point(38, 17).dy)
      ..quadraticBezierTo(
        point(50, 2).dx,
        point(50, 2).dy,
        point(62, 17).dx,
        point(62, 17).dy,
      )
      ..lineTo(point(92, 89).dx, point(92, 89).dy)
      ..lineTo(point(73, 89).dx, point(73, 89).dy)
      ..lineTo(point(50, 34).dx, point(50, 34).dy)
      ..lineTo(point(27, 89).dx, point(27, 89).dy)
      ..close();
    final innerCutout = Path()
      ..moveTo(point(41, 65).dx, point(41, 65).dy)
      ..lineTo(point(50, 43).dx, point(50, 43).dy)
      ..lineTo(point(59, 65).dx, point(59, 65).dy)
      ..close();
    final aMark = Path.combine(PathOperation.difference, outerA, innerCutout);
    final aExtrusion = Paint()
      ..style = PaintingStyle.fill
      ..color = blue.withValues(alpha: 0.88);
    for (var layer = 5; layer >= 1; layer--) {
      canvas.drawPath(
        mapPath(aMark, Offset(0, layer * 0.85 * scale)),
        aExtrusion,
      );
    }
    final metal = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          highlight,
          const Color(0xFFB9E4F3),
          const Color(0xFF739EB8),
        ],
        stops: const [0, 0.3, 0.68, 1],
      ).createShader(bounds);
    canvas.drawShadow(aMark, blue.withValues(alpha: 0.3), 3 * scale, false);
    canvas.drawPath(aMark, metal);
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15 * scale
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawPath(outerA, bevel);

    final arrow = Path()
      ..moveTo(point(5, 78).dx, point(5, 78).dy)
      ..cubicTo(
        point(27, 78).dx,
        point(27, 78).dy,
        point(51, 67).dx,
        point(51, 67).dy,
        point(70, 48).dx,
        point(70, 48).dy,
      )
      ..lineTo(point(86, 31).dx, point(86, 31).dy);
    final arrowHead = Path()
      ..moveTo(point(70, 29).dx, point(70, 29).dy)
      ..lineTo(point(92, 20).dx, point(92, 20).dy)
      ..lineTo(point(88, 43).dx, point(88, 43).dy)
      ..close();
    final arrowExtrusion = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = blue;
    canvas.drawPath(mapPath(arrow, Offset(0, 2.2 * scale)), arrowExtrusion);
    canvas.drawPath(
      mapPath(arrowHead, Offset(0, 2.2 * scale)),
      Paint()
        ..style = PaintingStyle.fill
        ..color = blue,
    );
    final arrowFace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [blue, cyan],
      ).createShader(bounds);
    canvas.drawPath(arrow, arrowFace);
    final arrowTipPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [blue, cyan],
      ).createShader(bounds);
    canvas.drawPath(arrowHead, arrowTipPaint);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.82),
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.highlight != highlight;
}
