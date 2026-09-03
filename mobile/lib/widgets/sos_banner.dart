import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SosBanner extends StatelessWidget {
  final List<dynamic>? alerts;
  final Map<String, dynamic>? activeIncident;
  final VoidCallback? onResolve;
  final Function(int alertId)? onResolveId;
  final VoidCallback? onTap;

  const SosBanner({
    super.key,
    this.alerts,
    this.activeIncident,
    this.onResolve,
    this.onResolveId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> activeAlerts = [];
    if (alerts != null) {
      activeAlerts = alerts!.where((a) => a['status'] != 'Resolved').toList();
    } else if (activeIncident != null) {
      if (activeIncident!['status'] != 'Resolved') {
        activeAlerts = [activeIncident!];
      }
    }

    if (activeAlerts.isEmpty) return const SizedBox.shrink();

    final first = activeAlerts.first;
    final code = first['incident_code'] ?? 'EMERGENCY';
    final desc = first['description'] ?? 'Emergency panic triggered';
    final count = activeAlerts.length;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.sosPulseGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.statusEmergency.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🚨 $count ACTIVE SOS EMERGENCY: $code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onResolve != null || onResolveId != null) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (onResolve != null) {
                    onResolve!();
                  } else if (onResolveId != null && first['id'] != null) {
                    onResolveId!(first['id']);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.statusEmergency,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
