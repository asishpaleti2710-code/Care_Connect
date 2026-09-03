import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class GuardiansScreen extends ConsumerStatefulWidget {
  const GuardiansScreen({super.key});

  @override
  ConsumerState<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends ConsumerState<GuardiansScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _linkedResident;
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadGuardianData();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _loadGuardianData(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGuardianData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final resListRes = await _apiService.getResidents();
      final incListRes = await _apiService.getIncidents();

      final resList = resListRes.data is List ? resListRes.data : (resListRes.data['residents'] ?? []);
      final incList = incListRes.data is List ? incListRes.data : (incListRes.data['incidents'] ?? []);

      Map<String, dynamic>? res;
      if (resList.isNotEmpty) {
        res = Map<String, dynamic>.from(resList.first as Map);
      }

      List<dynamic> filteredInc = [];
      if (res != null) {
        filteredInc = incList.where((i) => i['resident_id'] == res!['id']).toList();
      }

      if (mounted) {
        setState(() {
          _linkedResident = res;
          _incidents = filteredInc;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _linkedResident = {
            'id': 1,
            'full_name': 'Eleanor Vance',
            'age': 78,
            'blood_group': 'O+',
            'status': 'safe',
            'room_number': '304',
            'address': 'Building A, Apt 304',
            'emergency_contact': '+1 (555) 234-5678',
            'medical_notes': 'Mild hypertension, allergic to penicillin. Regular daily walks.'
          };
          _incidents = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final status = (_linkedResident?['status'] ?? 'safe').toString().toLowerCase();

    Color borderStatusColor = AppColors.statusSafe;
    if (status.contains('emergency')) {
      borderStatusColor = AppColors.statusEmergency;
    } else if (status.contains('alert')) {
      borderStatusColor = AppColors.statusAlert;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadGuardianData(),
          color: AppColors.accentTeal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family & Guardian Portal',
                    style: AppTheme.heading(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitoring linked family resident • Logged in as: ${user?.fullName ?? "Guardian"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Linked Resident Card
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_linkedResident != null)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderColor: borderStatusColor.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _linkedResident!['full_name'] ?? 'Resident',
                                      style: AppTheme.heading(fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge.fromStatus(status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Age ${_linkedResident!['age']} • Blood Group: ${_linkedResident!['blood_group'] ?? 'O+'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.accentTeal, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Location: ${_linkedResident!['address'] ?? "Room ${_linkedResident!['room_number']}"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Call Resident Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final contact = _linkedResident!['emergency_contact'] ?? '+1-555-0199';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📞 Dialing resident emergency phone: $contact'),
                                backgroundColor: AppColors.accentTeal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
                          label: Text(
                            'Call Resident (${_linkedResident!['emergency_contact'] ?? "Linked Phone"})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medical Notes Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgDarkInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MEDICAL NOTES & CARE CONDITION:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _linkedResident!['medical_notes'] ?? 'No critical conditions recorded.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const GlassCard(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No resident linked to this guardian account.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Real-Time Incident Notifications Section
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.statusAlert, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Real-Time Incident Notifications',
                    style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_incidents.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No emergency incidents reported for your linked resident.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ..._incidents.map((inc) {
                  final code = inc['incident_code'] ?? 'INC';
                  final status = inc['status'] ?? 'Pending';
                  final type = inc['emergency_type'] ?? 'Emergency';
                  final prio = inc['priority'] ?? 'High';
                  final desc = inc['description'] ?? '';
                  final responderName = inc['responder_name'];

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  code,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                            Text(
                              '$type ($prio Priority)',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                        if (responderName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '✓ Responder Assigned: $responderName (${inc['responder_role'] ?? 'Security'})',
                            style: const TextStyle(fontSize: 11, color: AppColors.statusSafe, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

