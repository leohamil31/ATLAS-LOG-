import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class AtlasLogo3D extends StatefulWidget {
  const AtlasLogo3D({
    super.key,
    this.size = 44,
    this.showWordmark = false,
  });

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
        label: 'Logo ATLAS-LOG, globo e rosa dos ventos',
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
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: glow),
                      blurRadius: _hovered ? 26 : 14,
                      spreadRadius: _hovered ? 2 : 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _AtlasGlobePainter(
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

class _AtlasGlobePainter extends CustomPainter {
  const _AtlasGlobePainter({
    required this.cyan,
    required this.blue,
    required this.highlight,
  });

  final Color cyan;
  final Color blue;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.39;
    final globeRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center.translate(0, radius * 0.16),
      radius * 1.2,
      Paint()
        ..color = cyan.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      center,
      radius * 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.035
        ..shader = SweepGradient(
          colors: [cyan.withValues(alpha: 0.08), cyan, blue, cyan],
        ).createShader(globeRect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.65),
          radius: 1.15,
          colors: [
            const Color(0xFF62F0FF),
            cyan,
            blue,
            const Color(0xFF102B59),
          ],
          stops: const [0, 0.24, 0.68, 1],
        ).createShader(globeRect),
    );

    final clip = Path()..addOval(globeRect);
    canvas.save();
    canvas.clipPath(clip);

    final gridPaint = Paint()
      ..color = highlight.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018;
    for (final factor in [0.38, 0.7]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * factor,
          height: radius * 2,
        ),
        gridPaint,
      );
    }
    for (final factor in [-0.48, 0.48]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, radius * factor),
          width: radius * 1.65,
          height: radius * 0.48,
        ),
        gridPaint,
      );
    }
    canvas.restore();

    final orbitPaint = Paint()
      ..color = highlight.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 5);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.75,
        height: radius * 0.86,
      ),
      math.pi * 0.04,
      math.pi * 0.92,
      false,
      orbitPaint,
    );
    canvas.restore();

    final compass = Path()
      ..moveTo(center.dx, center.dy - radius * 0.78)
      ..lineTo(center.dx + radius * 0.16, center.dy - radius * 0.08)
      ..lineTo(center.dx, center.dy + radius * 0.04)
      ..lineTo(center.dx - radius * 0.16, center.dy - radius * 0.08)
      ..close();
    canvas.drawPath(
      compass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, Colors.white, cyan],
        ).createShader(globeRect),
    );
    canvas.drawCircle(
      center,
      radius * 0.1,
      Paint()..color = highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasGlobePainter oldDelegate) =>
      oldDelegate.cyan != cyan ||
      oldDelegate.blue != blue ||
      oldDelegate.highlight != highlight;
}
