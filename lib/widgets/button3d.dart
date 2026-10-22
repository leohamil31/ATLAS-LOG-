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
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ac;
    final isSuccess = _phase == _Phase.success;
    final foreground = widget.secondary ? colors.text : Colors.white;
    final background = widget.secondary
        ? colors.surface
        : widget.color ?? colors.accent2;
    final borderRadius = BorderRadius.circular(8);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_phase == _Phase.loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        else ...[
          if (isSuccess)
            Icon(Icons.check_rounded, color: foreground, size: 18)
          else if (widget.icon != null)
            Icon(widget.icon, color: foreground, size: 18),
          if (widget.icon != null || isSuccess) const SizedBox(width: 8),
          Flexible(
            child: Text(
              isSuccess ? widget.successLabel ?? widget.label : widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: _enabled || _phase != _Phase.idle ? 1 : 0.55,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: widget.secondary ? colors.border : background,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? _tap : null,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 18,
              vertical: widget.compact ? 9 : 13,
            ),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}
