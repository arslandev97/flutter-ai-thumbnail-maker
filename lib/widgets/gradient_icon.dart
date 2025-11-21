import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient? gradient;

  const GradientIcon(this.icon, {super.key, required this.size, this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return (gradient ?? AppTheme.primaryGradient).createShader(bounds);
      },
      child: Icon(
        icon,
        size: size,
        color: Colors.white, // Required for ShaderMask to work
      ),
    );
  }
}
