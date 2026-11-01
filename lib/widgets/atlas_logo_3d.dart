import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'depth.dart';

/// Marca ATLAS LOG em 3D, desenhada em Canvas (sem assets, nítida em
/// qualquer tamanho).
///
/// Desenho: um "A" lapidado — cada perna tem duas faces (uma escura, uma
/// clara) — atravessado por uma flecha que sobe para a direita. Onde a flecha
/// cruza o "A" há um recorte real (BlendMode.clear), então o fundo aparece.
///
/// Movimento:
/// * entrada: a marca gira em Y e cresce até o lugar;
/// * reflexo de luz que varre a peça ao aparecer e no hover;
/// * [sway]: balanço lento contínuo (use só em telas de destaque);
/// * inclinação pelo ponteiro (Tilt3D) a partir de 56 px.
///
/// Tudo respeita "reduzir movimento" (AtlasMotion / context.reduceMotion).
class AtlasLogo3D extends StatefulWidget {
  const AtlasLogo3D({
    super.key,
    this.size = 44,
    this.showWordmark = false,
    this.extrude = true,
    this.interactive = true,
    this.sway = false,
  });

  final double size;
  final bool showWordmark;

  /// Desenha as camadas de extrusão (desligado automaticamente < 28 px).
  final bool extrude;

  /// Tilt pelo ponteiro + brilho no hover.
  final bool interactive;

  /// Balanço lento e contínuo em Y (login, splash, galeria).
  final bool sway;

  @override
  State<AtlasLogo3D> createState() => _AtlasLogo3DState();
}

class _AtlasLogo3DState extends State<AtlasLogo3D>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _intro.value = 1;
      return;
    }
    _intro.forward().whenComplete(() {
      if (!mounted) return;
      _sheen.forward(from: 0);
      if (widget.sway) _sway.repeat();
    });
  }

  @override
  void didUpdateWidget(AtlasLogo3D old) {
    super.didUpdateWidget(old);
    if (widget.sway == old.sway || context.reduceMotion) return;
    widget.sway ? _sway.repeat() : _sway.stop();
  }

  void _replay() {
    if (!widget.interactive || context.reduceMotion || _sheen.isAnimating) {
      return;
    }
    _sheen.forward(from: 0);
  }

  @override
  void dispose() {
    _intro.dispose();
    _sheen.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final size = widget.size;

    final painter = CustomPaint(
      painter: _AtlasMarkPainter(
        dark: colors.dark,
        extrude: widget.extrude && size >= 28,
        sheen: _sheen,
      ),
    );

    Widget mark = AnimatedBuilder(
      animation: Listenable.merge([_intro, _sway]),
      child: RepaintBoundary(child: SizedBox.square(dimension: size, child: painter)),
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_intro.value);
        final swayAngle = widget.sway
            ? math.sin(_sway.value * 2 * math.pi) * 0.32
            : 0.0;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(-2.4 * (1 - t) + swayAngle)
          ..rotateX(0.35 * (1 - t))
          ..scaleByDouble(0.5 + 0.5 * t, 0.5 + 0.5 * t, 1, 1);
        return Opacity(
          opacity: (t * 1.6).clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: m, child: child),
        );
      },
    );

    mark = MouseRegion(
      onEnter: (_) => _replay(),
      child: Semantics(label: 'Logo ATLAS LOG', image: true, child: mark),
    );

    if (widget.interactive && size >= 56) {
      mark = Tilt3D(maxTilt: 0.26, hoverScale: 1.04, glare: false, child: mark);
    }

    if (!widget.showWordmark) return mark;
    final brand = colors.dark ? Colors.white : const Color(0xFF0E3A6B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'ATLAS', style: TextStyle(color: brand)),
                  const TextSpan(
                    text: ' LOG',
                    style: TextStyle(color: Color(0xFF2BB3B1)),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
            Text(
              'CONNECTING THE WORLD',
              style: TextStyle(
                color: colors.muted,
                fontSize: size * 0.15,
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

/// Faces da marca no quadrado 100×100.
abstract final class _Mark {
  static const leftOuter = [Offset(48, 4), Offset(4, 86), Offset(20, 86)];
  static const leftInner = [
    Offset(48, 4),
    Offset(20, 86),
    Offset(34, 86),
    Offset(49, 36),
  ];
  static const rightInner = [
    Offset(48, 4),
    Offset(49, 36),
    Offset(70, 98),
    Offset(83, 98),
  ];
  static const rightOuter = [Offset(48, 4), Offset(83, 98), Offset(98, 98)];
  static const shaftTop = [
    Offset(0, 97),
    Offset(78, 27),
    Offset(82, 31),
    Offset(7, 97),
  ];
  static const shaftBottom = [
    Offset(7, 97),
    Offset(82, 31),
    Offset(86, 35),
    Offset(15, 97),
  ];
  static const headTop = [Offset(97, 12), Offset(69, 21), Offset(82, 31)];
  static const headBottom = [Offset(97, 12), Offset(82, 31), Offset(89, 41)];
  static const arrowOutline = [
    Offset(0, 97),
    Offset(78, 27),
    Offset(69, 21),
    Offset(97, 12),
    Offset(89, 41),
    Offset(86, 35),
    Offset(15, 97),
  ];
}

class _AtlasMarkPainter extends CustomPainter {
  _AtlasMarkPainter({
    required this.dark,
    required this.extrude,
    required this.sheen,
  }) : super(repaint: sheen);

  final bool dark;
  final bool extrude;
  final Animation<double> sheen;

  // Paleta da marca. No escuro, os azuis profundos clareiam para manter
  // contraste com o fundo.
  Color get _navyTop => dark ? const Color(0xFF3A82C8) : const Color(0xFF1C5C99);
  Color get _navyBottom =>
      dark ? const Color(0xFF1C5C99) : const Color(0xFF0A2A4F);
  static const _tealTop = Color(0xFF5FD0C8);
  static const _tealBottom = Color(0xFF1A8790);
  static const _teal = Color(0xFF2BB3B1);
  static const _blue = Color(0xFF1E5F9E);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final origin = Offset(
      (size.width - unit) / 2,
      (size.height - unit) / 2,
    );
    final scale = unit / 100;
    Path poly(List<Offset> pts) =>
        Path()..addPolygon([for (final p in pts) origin + p * scale], true);

    final rect = origin & Size.square(unit);
    Paint grad(List<Color> c, {bool diagonal = false}) => Paint()
      ..shader = LinearGradient(
        begin: diagonal ? Alignment.bottomLeft : Alignment.topCenter,
        end: diagonal ? Alignment.topRight : Alignment.bottomCenter,
        colors: c,
      ).createShader(rect);

    final legsNavy = [poly(_Mark.leftOuter), poly(_Mark.rightOuter)];
    final legsLight = [poly(_Mark.leftInner), poly(_Mark.rightInner)];
    final arrowNavy = [poly(_Mark.shaftBottom), poly(_Mark.headBottom)];
    final arrowLight = [poly(_Mark.shaftTop), poly(_Mark.headTop)];

    void extrusion(List<Path> navy, List<Path> light) {
      if (!extrude) return;
      final layers = math.max(4, (unit * 0.09).round());
      final step = unit * 0.011;
      for (var i = layers; i >= 1; i--) {
        final k = i / layers;
        final o = Offset(step * i * 0.7, step * i);
        final navyEdge = AtlasLight.shade(AtlasLight.edge(_navyBottom), -0.3 * k);
        final lightEdge = AtlasLight.shade(AtlasLight.edge(_tealBottom), -0.3 * k);
        for (final p in navy) {
          canvas.drawPath(p.shift(o), Paint()..color = navyEdge);
        }
        for (final p in light) {
          canvas.drawPath(p.shift(o), Paint()..color = lightEdge);
        }
      }
    }

    canvas.saveLayer(rect.inflate(unit * 0.2), Paint());

    // 1. "A" (extrusão + faces).
    extrusion(legsNavy, legsLight);
    canvas
      ..drawPath(legsNavy[0], grad([_navyTop, _navyBottom]))
      ..drawPath(legsLight[0], grad([_tealTop, _tealBottom]))
      ..drawPath(legsLight[1], grad([_teal, _blue]))
      ..drawPath(
        legsNavy[1],
        grad([AtlasLight.shade(_navyTop, -0.1), AtlasLight.shade(_navyBottom, 0.02)]),
      );

    // 2. Recorte em volta da flecha: abre um respiro real no "A".
    canvas.drawPath(
      poly(_Mark.arrowOutline),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scale
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Flecha (extrusão + faces).
    extrusion(arrowNavy, arrowLight);
    final arrowLit = grad([const Color(0xFF1F6FA8), const Color(0xFF6ADAD0)], diagonal: true);
    final arrowShade = grad([_navyBottom, _navyTop], diagonal: true);
    for (final p in arrowLight) {
      canvas.drawPath(p, arrowLit);
    }
    for (final p in arrowNavy) {
      canvas.drawPath(p, arrowShade);
    }

    // 4. Arestas de luz (lapidação).
    final ridge = Paint()
      ..color = Colors.white.withValues(alpha: dark ? 0.22 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, 0.5 * scale);
    canvas
      ..drawLine(origin + const Offset(48, 4) * scale, origin + const Offset(20, 86) * scale, ridge)
      ..drawLine(origin + const Offset(48, 4) * scale, origin + const Offset(83, 98) * scale, ridge)
      ..drawLine(origin + const Offset(7, 97) * scale, origin + const Offset(82, 31) * scale, ridge);

    // 5. Varredura de brilho, recortada à marca.
    final t = sheen.value;
    if (t > 0 && t < 1) {
      final all = Path();
      for (final p in [...legsNavy, ...legsLight, ...arrowNavy, ...arrowLight]) {
        all.addPath(p, Offset.zero);
      }
      final x = -0.6 + 2.2 * Curves.easeInOut.transform(t);
      canvas
        ..save()
        ..clipPath(all)
        ..drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment(-1 + x * 2 - 0.5, -1),
              end: Alignment(-1 + x * 2 + 0.5, 1),
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(rect),
        )
        ..restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtlasMarkPainter old) =>
      old.dark != dark || old.extrude != extrude;
}
