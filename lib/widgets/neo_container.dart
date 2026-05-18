import 'package:flutter/material.dart';

class NeoContainer extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final bool isPressed;
  final VoidCallback? onTap;

  const NeoContainer({
    super.key,
    required this.child,
    this.padding = 20.0,
    this.borderRadius = 20.0,
    this.isPressed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF1E1E2C);
    final darkShadow = bgColor.withOpacity(0.5);
    final lightShadow = Colors.white.withOpacity(0.05);

    final innerContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: darkShadow,
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: lightShadow,
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: darkShadow,
                  offset: const Offset(8, 8),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: lightShadow,
                  offset: const Offset(-8, -8),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: innerContainer,
      );
    }
    return innerContainer;
  }
}
