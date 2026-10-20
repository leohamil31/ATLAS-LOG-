/// Botão com relevo 3D: sombras em camadas, borda de luz, elevação no hover,
/// afundamento no clique, gradiente animado, ripple e feedback de
/// carregando/sucesso.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum _Phase { idle, loading, success }

class Button3D extends StatefulWidget {
  const Button3D({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.onAction,
    this.color,
    this.secondary = false,
    this.compact = false,
    this.successLabel,
  });

  final String label;
  final IconData? icon;

  /// Ação síncrona simples (mostra apenas o relevo/ripple).
  final VoidCallback? onPressed;

  /// Ação com feedback: spinner enquanto roda e check ao terminar.
  /// Retornar `false` pula o estado de sucesso.
  final FutureOr<bool> Function()? onAction;

  final Color? color;
  final bool secondary;
  final bool compact;
  final String? successLabel;

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _hover = false;
  bool _down = false;
  _Phase _phase = _Phase.idle;

  bool get _enabled =>
      (widget.onPressed != null || widget.onAction != null) &&
      _phase == _Phase.idle;

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    setState(() => _hover = v);
    if (context.reduceMotion || widget.secondary) return;
    if (v) {
      _shine.repeat();
    } else {
      _shine.stop();
    }
  }

  Future<void> _tap() async {
    if (!_enabled) return;
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }
    final reduce = context.reduceMotion;
    setState(() => _phase = _Phase.loading);
    final ok = await widget.onAction!();
    if (!mounted) return;
    if (!ok) {
      setState(() => _phase = _Phase.idle);
      return;
    }
    setState(() => _phase = _Phase.success);
    await Future<void>.delayed(
      reduce ? const Duration(milliseconds: 300) : const Duration(milliseconds: 800),
    );
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final reduce = context.reduceMotion;
    final base = widget.color ?? ac.accent2;
    final isSuccess = _phase == _Phase.success;
    final fill = isSuccess ? ac.success : base;
    final light = Color.lerp(fill, Colors.white, 0.3)!;
    final dark = Color.lerp(fill, Colors.black, 0.35)!;
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 160);
    final lift = _down ? 1.0 : (_hover && !reduce ? -2.0 : 0.0);
    final scale = _down && !reduce ? 0.98 : 1.0;
    final radius = BorderRadius.circular(widget.compact ? 10 : 14);
    final fg = widget.secondary ? ac.text : Colors.white;

    Widget content;
    switch (_phase) {
      case _Phase.loading:
        content = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
        );
      case _Phase.success:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1),
              duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(Icons.check_circle_rounded, color: fg, size: 20),
            ),
            if (widget.successLabel != null) ...[
              const SizedBox(width: 8),
              Text(widget.successLabel!, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            ],
          ],
        );
      case _Phase.idle:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
    }

    return Opacity(
      opacity: (widget.onPressed == null && widget.onAction == null) ? 0.5 : 1,
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) {
          _setHover(false);
          if (_down) setState(() => _down = false);
        },
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: dur,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, lift, 0)
            ..scaleByDouble(scale, scale, 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: widget.secondary
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: ac.dark ? 0.4 : 0.1),
                      offset: Offset(0, _down ? 1 : 3),
                    ),
                  ]
                : [
                    BoxShadow(color: dark, offset: Offset(0, _down ? 1 : 4)),
                    BoxShadow(
                      color: fill.withValues(alpha: _hover ? 0.55 : 0.25),
                      blurRadius: _hover ? 18 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: AnimatedBuilder(
            animation: _shine,
            builder: (_, child) {
              final t = _shine.value;
              final decoration = widget.secondary
                  ? BoxDecoration(
                      borderRadius: radius,
                      color: ac.card,
                      border: Border.all(color: _hover ? ac.accent : ac.border),
                    )
                  : BoxDecoration(
                      borderRadius: radius,
                      // Gradiente que "desliza" enquanto o mouse está em cima.
                      gradient: LinearGradient(
                        begin: Alignment(-1 + 2 * t, -1),
                        end: Alignment(1 + 2 * t, 1),
                        colors: [light, fill, dark, fill, light],
                        stops: const [0, 0.3, 0.5, 0.7, 1],
                        tileMode: TileMode.mirror,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    );
              return DecoratedBox(decoration: decoration, child: child);
            },
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: _enabled ? _tap : null,
                onHighlightChanged: (v) => setState(() => _down = v),
                splashColor: Colors.white.withValues(alpha: 0.25),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 12 : 20,
                    vertical: widget.compact ? 8 : 13,
                  ),
                  child: AnimatedSize(
                    duration: dur,
                    child: Center(widthFactor: 1, child: content),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
