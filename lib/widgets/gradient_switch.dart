import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GradientSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Gradient? gradient;

  const GradientSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value ? (gradient ?? AppTheme.primaryGradient) : null,
          color: value ? null : Colors.grey[800],
          border: Border.all(
            color: value ? Colors.transparent : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
