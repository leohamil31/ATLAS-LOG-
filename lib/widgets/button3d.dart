import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum _Phase { idle, loading, success }

/// Botão principal do ATLAS LOG, construído como uma tecla física.
///
/// * face iluminada (gradiente de marca + reflexo) sobre uma borda escura;
/// * hover: a face sobe 1 px e o halo cresce; press: a face afunda na borda;
/// * foco por teclado: anel de 2 px na cor de destaque;
/// * `onAction` assíncrono → spinner → ✓ verde → volta ao normal, com
///   crossfade entre as fases (feedback claro para ações de CRUD).
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
  final VoidCallback? onPressed;
  final FutureOr<bool> Function()? onAction;
  final Color? color;
  final bool secondary;
  final bool compact;
  final String? successLabel;

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> {
  _Phase _phase = _Phase.idle;
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled =>
      (widget.onPressed != null || widget.onAction != null) &&
      _phase == _Phase.idle;

  Future<void> _tap() async {
    if (!_enabled) return;
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    setState(() => _phase = _Phase.loading);
    final ok = await widget.onAction!();
    if (!mounted) return;
    if (!ok) {
      setState(() => _phase = _Phase.idle);
      return;
    }
    setState(() => _phase = _Phase.success);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final isSuccess = _phase == _Phase.success;
    final secondary = widget.secondary && !isSuccess;
    final foreground = secondary ? colors.text : Colors.white;
    final base = isSuccess ? colors.success : widget.color ?? colors.accent2;
    final radius = BorderRadius.circular(AtlasRadius.sm);
    final active = _enabled && _hover && !context.reduceMotion;
    final fast = AtlasMotion.of(context, AtlasMotion.fast);

    final gradient = secondary
        ? null
        : widget.color == null && !isSuccess
        ? colors.brandGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, Colors.black, 0.18)!],
          );

    final Widget phaseContent = switch (_phase) {
      _Phase.loading => SizedBox(
        key: const ValueKey('loading'),
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
      ),
      _ => Row(
        key: ValueKey(_phase),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSuccess)
            Icon(Icons.check_rounded, color: foreground, size: 18)
          else if (widget.icon != null)
            AnimatedSlide(
              offset: active ? const Offset(0.08, 0) : Offset.zero,
              duration: fast,
              child: Icon(
                widget.icon,
                color: secondary ? colors.accent : foreground,
                size: 18,
              ),
            ),
          if (widget.icon != null || isSuccess) const SizedBox(width: 8),
          Flexible(
            child: Text(
              isSuccess ? widget.successLabel ?? widget.label : widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    };

    final content = AnimatedSwitcher(
      duration: AtlasMotion.of(context, AtlasMotion.base),
      switchInCurve: AtlasMotion.enter,
      switchOutCurve: AtlasMotion.exit,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: phaseContent,
    );

    // ---- Tecla física -------------------------------------------------
    // A borda (lateral escura) fica atrás; a face iluminada repousa sobre
    // ela. Hover: a face sobe 1 px. Press: a face desce até quase cobrir a
    // borda — a sensação de "afundar" vem da geometria, não só da cor.
    final edgeDepth = widget.compact ? 3.0 : 4.0;
    final reduce = context.reduceMotion;
    final down = _pressed && _enabled;
    final faceY = down
        ? edgeDepth - 1
        : (active && !reduce ? -1.0 : 0.0);
    final edgeColor = secondary
        ? AtlasLight.shade(colors.border, colors.dark ? -0.1 : -0.12)
        : AtlasLight.edge(base);
    final faceRadius = radius;

    final face = AnimatedContainer(
      duration: down ? AtlasMotion.instant : fast,
      curve: AtlasMotion.standard,
      transform: Matrix4.translationValues(0, faceY, 0),
      decoration: BoxDecoration(
        borderRadius: faceRadius,
        gradient: secondary ? null : gradient,
        color: secondary
            ? (active
                  ? Color.alphaBlend(
                      colors.accent2.withValues(alpha: 0.06),
                      colors.surface,
                    )
                  : colors.surface)
            : null,
        border: Border.all(
          color: _focused
              ? colors.accent
              : secondary
              ? (active
                    ? colors.accent2.withValues(alpha: 0.5)
                    : colors.border)
              : Colors.white.withValues(alpha: 0.18),
          width: _focused ? 2 : 1,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: faceRadius,
        // Reflexo no topo da tecla (mais forte no hover, some ao pressionar).
        gradient: AtlasLight.sheen(
          strength: down ? 0.2 : (active ? 1 : 0.7),
          dark: colors.dark || secondary,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _enabled ? _tap : null,
          onHover: (h) => setState(() => _hover = h),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          borderRadius: faceRadius,
          splashColor: Colors.white.withValues(alpha: 0.18),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 18,
              vertical: widget.compact ? 8 : 11,
            ),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: _enabled || _phase != _Phase.idle ? 1 : 0.5,
      duration: fast,
      child: AnimatedContainer(
        duration: fast,
        curve: AtlasMotion.standard,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: edgeColor,
          boxShadow: down
              ? AtlasLight.elevation(
                  secondary ? colors.shadow : base,
                  0.05,
                  dark: colors.dark,
                )
              : secondary
              ? AtlasLight.elevation(
                  colors.shadow,
                  active ? 0.35 : 0.15,
                  dark: colors.dark,
                )
              : AtlasShadows.glow(base, strength: active ? 1.25 : 0.8),
        ),
        // A face ocupa tudo menos a borda inferior visível.
        padding: EdgeInsets.only(bottom: edgeDepth),
        child: face,
      ),
    );
  }
}
