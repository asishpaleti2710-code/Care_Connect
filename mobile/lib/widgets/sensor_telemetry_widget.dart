import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'glass_card.dart';

class SensorTelemetryWidget extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> payload)? onSimulateEmergency;

  const SensorTelemetryWidget({super.key, this.onSimulateEmergency});

  @override
  State<SensorTelemetryWidget> createState() => _SensorTelemetryWidgetState();
}

class _SensorTelemetryWidgetState extends State<SensorTelemetryWidget> {
  int _heartRate = 74;
  int _spO2 = 98;
  double _temperature = 98.4;
  String _accelerometerStatus = 'Normal Motion';
  bool _isFallDetected = false;
  Timer? _vitalsTimer;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _vitalsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        if (!_isFallDetected) {
          _heartRate = 70 + _rnd.nextInt(8);
          _spO2 = 97 + _rnd.nextInt(3);
          _temperature = double.parse((98.2 + _rnd.nextDouble() * 0.4).toStringAsFixed(1));
        }
      });
    });
  }

  @override
  void dispose() {
    _vitalsTimer?.cancel();
    super.dispose();
  }

  void _triggerSimulatedEvent(String type, String desc, int hr, int spo2) {
    setState(() {
      _isFallDetected = true;
      _heartRate = hr;
      _spO2 = spo2;
      _accelerometerStatus = type == 'Fall Anomaly' ? '⚠️ High Impact Fall Detected (3.4G)' : 'Critical Physiological Anomaly';
    });

    if (widget.onSimulateEmergency != null) {
      widget.onSimulateEmergency!({
        'type': type,
        'priority': 'Critical',
        'description': desc,
      });
    }

    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _isFallDetected = false;
          _accelerometerStatus = 'Normal Motion';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      backgroundColor: _isFallDetected ? AppColors.statusEmergency.withValues(alpha: 0.15) : AppColors.bgCard,
      borderColor: _isFallDetected ? AppColors.statusEmergency : AppColors.accentTeal.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sensors_rounded, color: AppColors.accentTeal, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IoT Smart Wearable Telemetry',
                        style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Live continuous resident vitals stream',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isFallDetected ? AppColors.statusEmergency : AppColors.statusSafe).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: _isFallDetected ? AppColors.statusEmergency : AppColors.statusSafe,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isFallDetected ? AppColors.statusEmergency : AppColors.statusSafe,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFallDetected ? 'ANOMALY ALERT' : 'LIVE STREAM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _isFallDetected ? AppColors.statusEmergency : AppColors.statusSafe,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vitals Metrics Grid
          Row(
            children: [
              // Heart Rate
              Expanded(
                child: _VitalPill(
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.statusEmergency,
                  label: 'Heart Rate',
                  value: '$_heartRate bpm',
                  isWarning: _heartRate > 110,
                ),
              ),
              const SizedBox(width: 8),

              // SpO2
              Expanded(
                child: _VitalPill(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.accentBlue,
                  label: 'Blood Oxygen',
                  value: '$_spO2% SpO2',
                  isWarning: _spO2 < 90,
                ),
              ),
              const SizedBox(width: 8),

              // Temp
              Expanded(
                child: _VitalPill(
                  icon: Icons.thermostat_rounded,
                  iconColor: AppColors.statusAlert,
                  label: 'Body Temp',
                  value: '$_temperature°F',
                  isWarning: _temperature > 100.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Accelerometer Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgDarkInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFallDetected ? AppColors.statusEmergency.withValues(alpha: 0.5) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.airline_seat_recline_extra_rounded,
                  size: 16,
                  color: _isFallDetected ? AppColors.statusEmergency : AppColors.accentTeal,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Motion Sensor: ',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    _accelerometerStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isFallDetected ? AppColors.statusEmergency : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Simulation Quick Triggers
          const Text(
            'TEST IOT EMERGENCY DISPATCH SIMULATION:',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SimButton(
                label: '⚡ Simulate Sudden Fall',
                color: AppColors.statusEmergency,
                onPressed: () => _triggerSimulatedEvent(
                  'Fall Anomaly',
                  'IoT Wearable: 3.4G Sudden Impact Fall detected in living area.',
                  125,
                  94,
                ),
              ),
              _SimButton(
                label: '💔 Cardiac Spike (>130)',
                color: AppColors.statusAlert,
                onPressed: () => _triggerSimulatedEvent(
                  'Medical Emergency',
                  'IoT Wearable: Critical Tachycardia spike detected (135 bpm).',
                  135,
                  95,
                ),
              ),
              _SimButton(
                label: '📉 Hypoxia Drop (<88%)',
                color: AppColors.accentBlue,
                onPressed: () => _triggerSimulatedEvent(
                  'Medical Emergency',
                  'IoT Wearable: Severe SpO2 drop to 86% detected.',
                  102,
                  86,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isWarning;

  const _VitalPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.statusEmergency.withValues(alpha: 0.2) : AppColors.bgDarkInput,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarning ? AppColors.statusEmergency : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isWarning ? AppColors.statusEmergency : iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isWarning ? AppColors.statusEmergency : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SimButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
