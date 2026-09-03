import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum BadgeType { safe, alert, emergency, custom }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType? type;
  final Color? customColor;
  final Color? customBgColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.type,
    this.customColor,
    this.customBgColor,
    this.icon,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory StatusBadge.fromStatus(String status, {double fontSize = 11.0}) {
    final s = status.toLowerCase();
    if (s.contains('safe') || s.contains('resolved') || s.contains('stable')) {
      return StatusBadge(label: status.toUpperCase(), type: BadgeType.safe, fontSize: fontSize);
    } else if (s.contains('emergency') || s.contains('critical') || s.contains('pending')) {
      return StatusBadge(label: status.toUpperCase(), type: BadgeType.emergency, fontSize: fontSize);
    } else {
      return StatusBadge(label: status.toUpperCase(), type: BadgeType.alert, fontSize: fontSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (type) {
      case BadgeType.safe:
        textColor = AppColors.statusSafe;
        bgColor = AppColors.statusSafeBg;
        borderColor = AppColors.statusSafe.withValues(alpha: 0.3);
        break;
      case BadgeType.alert:
        textColor = AppColors.statusAlert;
        bgColor = AppColors.statusAlertBg;
        borderColor = AppColors.statusAlert.withValues(alpha: 0.3);
        break;
      case BadgeType.emergency:
        textColor = AppColors.statusEmergency;
        bgColor = AppColors.statusEmergencyBg;
        borderColor = AppColors.statusEmergency.withValues(alpha: 0.5);
        break;
      default:
        textColor = customColor ?? AppColors.accentTeal;
        bgColor = customBgColor ?? textColor.withValues(alpha: 0.15);
        borderColor = textColor.withValues(alpha: 0.3);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
