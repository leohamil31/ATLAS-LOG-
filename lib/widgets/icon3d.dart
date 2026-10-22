import 'package:flutter/material.dart';

import '../core/theme.dart';

enum IconMotion { spin, drive, tilt, pulse, pop, bounce }

/// Ícone de navegação plano; motion fica disponível para compatibilidade.
class Icon3D extends StatelessWidget {
  const Icon3D({
    super.key,
    required this.icon,
    required this.color,
    this.motion = IconMotion.tilt,
    this.size = 40,
    this.animate = false,
    this.loop = false,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final IconMotion motion;
  final double size;
  final bool animate;
  final bool loop;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final iconColor = muted ? context.ac.muted : color;
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: Icon(icon, size: size * 0.62, color: iconColor)),
    );
  }
}
