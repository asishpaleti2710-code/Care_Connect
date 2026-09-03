import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Border? customBorder;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.radius = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.customBorder,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.bgCard) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: customBorder ??
            Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }

    return content;
  }
}
