import 'package:flutter/material.dart';

import '../core/theme.dart';

class AtlasLogo3D extends StatelessWidget {
  const AtlasLogo3D({super.key, this.size = 44, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final mark = Semantics(
      label: 'Logo ATLAS LOG',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AtlasMarkPainter(
            primary: colors.text,
            accent: colors.accent2,
          ),
        ),
      ),
    );

    if (!showWordmark) return mark;
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
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'GESTÃO LOGÍSTICA',
              style: TextStyle(
                color: colors.muted,
                fontSize: size * 0.16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AtlasMarkPainter extends CustomPainter {
  const _AtlasMarkPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
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
    canvas
      ..drawPath(leftLeg, Paint()..color = primary)
      ..drawPath(rightLeg, Paint()..color = primary);

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
    canvas.drawPath(arrow, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.accent != accent;
}
