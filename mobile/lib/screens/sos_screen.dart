import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/sensor_telemetry_widget.dart';
import '../widgets/sos_banner.dart';
import '../widgets/status_badge.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _activeIncident;
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  Timer? _incidentRefreshTimer;
  List<dynamic> _myIncidents = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Map<String, dynamic> _residentProfile = {
    'full_name': 'Eleanor Vance',
    'age': 78,
    'blood_group': 'O+',
    'room_number': '304',
    'address': 'Building A, Apt 304',
    'emergency_contact': '+1 (555) 234-5678',
    'medical_notes': 'Mild hypertension, allergic to penicillin. Regular daily walks.',
    'physician': 'Dr. Robert Miller (+1 555-876-5432)'
  };

  final List<Map<String, String>> _guardians = [
    {
      'name': 'Sarah Vance',
      'relation': 'Daughter / Primary Contact',
      'phone': '+1 (555) 234-5678',
    },
    {
      'name': 'Dr. Robert Miller',
      'relation': 'Attending Physician',
      'phone': '+1 (555) 876-5432',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadIncidentHistory();
    _incidentRefreshTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadIncidentHistory(silent: true));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _incidentRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidentHistory({bool silent = false}) async {
    try {
      final res = await _apiService.getIncidents();
      final list = res.data is List ? res.data : (res.data['incidents'] ?? []);
      if (mounted) {
        setState(() {
          _myIncidents = list;
          final active = list.firstWhere(
            (i) => i['status'] != 'Resolved',
            orElse: () => null,
          );
          if (active != null) {
            _activeIncident = Map<String, dynamic>.from(active as Map);
          } else {
            _activeIncident = null;
          }
        });
      }
    } catch (_) {}
  }

  void _startCountdownAndTrigger([String category = 'Medical Emergency', String? details]) {
    setState(() {
      _countdownSeconds = 3;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_countdownSeconds > 1) {
                setDialogState(() => _countdownSeconds--);
                setState(() => _countdownSeconds = _countdownSeconds);
              } else {
                timer.cancel();
                _countdownTimer = null;
                Navigator.of(dialogCtx, rootNavigator: true).pop();
                _executeSosDispatch(category, details);
              }
            });

            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.statusEmergency, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.statusEmergency, size: 28),
                  SizedBox(width: 8),
                  Text('Triggering SOS Alert...', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Emergency responders and security will be dispatched in:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.statusEmergency.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.statusEmergency, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdownSeconds',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.statusEmergency),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hold tight or press cancel if triggered accidentally.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      _countdownTimer = null;
                      Navigator.of(dialogCtx, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SOS Trigger Cancelled'), backgroundColor: AppColors.statusAlert),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('CANCEL SOS DISPATCH'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeSosDispatch(String category, String? details) async {
    final user = ref.read(authProvider).user;
    final userName = user?.fullName ?? 'CareConnect Member';
    final userEmail = user?.email ?? 'resident@careconnect.org';

    developer.log(
      '[SOS TRIGGER] Initiating emergency dispatch. User: $userName ($userEmail), Category: $category',
      name: 'CareConnect.SOS',
    );

    try {
      // 1. Primary SOS Alert dispatch (/api/sos) - triggers immediate email to user + tiered routing
      final primaryResponse = await _apiService.createSosAlert(
        category: category,
        message: details ?? 'Immediate emergency assistance requested by $userName.',
        latitude: 13.0827,
        longitude: 80.2707,
      );

      developer.log(
        '[SOS API SUCCESS] /api/sos returned status: ${primaryResponse.statusCode}',
        name: 'CareConnect.SOS',
      );

      // 2. Also register in legacy incidents tracker for real-time dashboard sync
      try {
        await _apiService.triggerSos(
          category,
          'Building A, Apt 304',
          13.0827,
          80.2707,
          description: details ?? 'Immediate emergency assistance requested by $userName.',
        );
      } catch (_) {}

      final data = primaryResponse.data;
      final alertId = data['id'] ?? 999;

      if (mounted) {
        setState(() {
          _activeIncident = {
            'id': alertId,
            'incident_code': 'SOS-$alertId',
            'emergency_type': category,
            'location': 'Building A, Apt 304',
            'status': 'ACTIVE',
            'description': details ?? 'Emergency signal broadcasted.',
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🚨 SOS Alert #$alertId Broadcasted! Email notification sent to $userEmail',
            ),
            backgroundColor: AppColors.statusEmergency,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        _loadIncidentHistory(silent: true);
      }
    } catch (e) {
      developer.log(
        '[SOS DISPATCH EXCEPTION] Failed to connect to server: $e',
        name: 'CareConnect.SOS',
      );

      if (mounted) {
        setState(() {
          _activeIncident = {
            'id': 101,
            'incident_code': 'INC-101',
            'emergency_type': category,
            'location': 'Building A, Apt 304',
            'status': 'Pending',
            'description': details ?? 'Emergency signal broadcasted.',
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ SOS Alert triggered locally. Server sync issue: ${e.toString()}'),
            backgroundColor: AppColors.statusAlert,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCategoryChooser() {
    final categories = [
      {'name': 'Medical Emergency', 'icon': Icons.medical_services_rounded, 'color': AppColors.statusEmergency},
      {'name': 'Fall Anomaly', 'icon': Icons.personal_injury_rounded, 'color': AppColors.statusAlert},
      {'name': 'Fire / Smoke', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orange},
      {'name': 'Security Threat', 'icon': Icons.shield_rounded, 'color': AppColors.accentPurple},
      {'name': 'General Assistance', 'icon': Icons.help_outline_rounded, 'color': AppColors.accentTeal},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Emergency Category', style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...categories.map((c) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (c['color'] as Color).withValues(alpha: 0.2),
                    child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 20),
                  ),
                  title: Text(c['name'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _startCountdownAndTrigger(c['name'] as String);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final resName = user?.fullName ?? _residentProfile['full_name'];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadIncidentHistory(),
          color: AppColors.accentTeal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active SOS Banner
              if (_activeIncident != null) ...[
                SosBanner(
                  activeIncident: _activeIncident,
                  onResolve: () async {
                    if (_activeIncident!['id'] != null) {
                      await _apiService.updateIncidentStatus(_activeIncident!['id'], 'Resolved');
                    }
                    setState(() => _activeIncident = null);
                    _loadIncidentHistory(silent: true);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resident Care Portal',
                        style: AppTheme.heading(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome back, $resName • Room ${_residentProfile["room_number"]}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  StatusBadge.fromStatus(_activeIncident != null ? 'emergency' : 'safe'),
                ],
              ),
              const SizedBox(height: 20),

              // IoT Smart Wearable Telemetry Widget matching web SensorTelemetryWidget.jsx
              const SensorTelemetryWidget(),
              const SizedBox(height: 20),

              // Pulsing Big SOS Emergency Button matching web ResidentDashboard.jsx
              GlassCard(
                padding: const EdgeInsets.all(24),
                borderColor: AppColors.statusEmergency.withValues(alpha: 0.4),
                child: Column(
                  children: [
                    Text(
                      'INSTANT RESCUE DISPATCH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusEmergency.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Press button below to instantly alert campus security, EMTs, & family.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Big Pulsing Button
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: GestureDetector(
                        onTap: () => _startCountdownAndTrigger('Medical Emergency'),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.statusEmergency.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded, color: Colors.white, size: 36),
                              SizedBox(height: 4),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'PRESS NOW',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Chooser Button
                    OutlinedButton.icon(
                      onPressed: _showCategoryChooser,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.glassBorder),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.category_outlined, size: 16, color: AppColors.accentTeal),
                      label: const Text('Choose Specific Emergency Category', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Resident Medical & Care Card matching web ResidentDashboard.jsx
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, color: AppColors.accentTeal, size: 20),
                            const SizedBox(width: 8),
                            Text('Resident Medical Profile', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Blood: ${_residentProfile["blood_group"]}',
                            style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Full Name: $resName (Age ${_residentProfile["age"]})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Location: ${_residentProfile["address"]}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Attending: ${_residentProfile["physician"]}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkInput,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'MEDICAL CONDITIONS: ${_residentProfile["medical_notes"]}',
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Linked Family Guardians Roster
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Text('Linked Family Guardians', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._guardians.map((g) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                Text(g['relation']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_forwarded_rounded, color: AppColors.statusSafe, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('📞 Dialing: ${g['phone']}')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Incident History
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text('Recent Emergency History', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),

              if (_myIncidents.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No past incidents recorded.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                )
              else
                ..._myIncidents.take(4).map((inc) {
                  final code = inc['incident_code'] ?? 'INC';
                  final status = inc['status'] ?? 'Resolved';
                  final type = inc['emergency_type'] ?? 'Emergency';

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        StatusBadge.fromStatus(status),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
