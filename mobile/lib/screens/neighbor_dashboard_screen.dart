import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class NeighborDashboardScreen extends ConsumerStatefulWidget {
  const NeighborDashboardScreen({super.key});

  @override
  ConsumerState<NeighborDashboardScreen> createState() => _NeighborDashboardScreenState();
}

class _NeighborDashboardScreenState extends ConsumerState<NeighborDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _incidents = [];
  Map<int, dynamic> _residentsMap = {};
  bool _isLoading = true;
  int? _respondingId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final incRes = await _apiService.getIncidents();
      final resRes = await _apiService.getResidents();

      final incList = incRes.data is List ? incRes.data : (incRes.data['incidents'] ?? []);
      final resList = resRes.data is List ? resRes.data : (resRes.data['residents'] ?? []);

      final rMap = <int, dynamic>{};
      for (final r in resList) {
        if (r['id'] != null) rMap[r['id']] = r;
      }

      if (mounted) {
        setState(() {
          _incidents = incList;
          _residentsMap = rMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _incidents = [
            {
              'id': 201,
              'incident_code': 'INC-201',
              'resident_id': 1,
              'emergency_type': 'Fall Anomaly',
              'priority': 'Critical',
              'status': 'Pending',
              'location': 'Building A, Room 304',
              'description': 'Senior neighbor slipped in bathroom and triggered SOS.',
            },
          ];
          _residentsMap = {
            1: {
              'id': 1,
              'full_name': 'Eleanor Vance',
              'age': 78,
              'blood_group': 'O+',
              'room_number': '304',
              'address': 'Building A, Apt 304',
            }
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNeighborRespond(int incidentId) async {
    final user = ref.read(authProvider).user;
    setState(() => _respondingId = incidentId);

    try {
      await _apiService.updateIncidentStatus(
        incidentId,
        'Accepted',
        responderName: user?.fullName ?? 'Community Neighbor Responder',
        responderRole: 'Community Neighbor Responder',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🤝 Emergency accepted! You are on your way to assist.'),
            backgroundColor: AppColors.statusSafe,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadData(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error offering help: $e'),
            backgroundColor: AppColors.statusEmergency,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _respondingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final activeAlerts = _incidents.where((i) => i['status'] != 'Resolved').toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadData(),
          color: AppColors.accentTeal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Motto Banner
              GlassCard(
                padding: const EdgeInsets.all(20),
                gradient: const LinearGradient(
                  colors: [Color(0x3314B8A6), Color(0xF20F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppColors.accentTeal.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.tealGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentTeal.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Neighborhood Responder Network',
                                style: AppTheme.heading(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '"Every Second Matters. Every Neighbor Can Help."',
                                style: TextStyle(
                                  color: AppColors.accentTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusEmergency.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: AppColors.statusEmergency.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '🚨 ${activeAlerts.length} Active Local Emergencies',
                        style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: AppColors.statusEmergency, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Nearby Resident Emergency Broadcasts',
                    style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Broadcast List
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (activeAlerts.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppColors.statusSafe, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'No active emergency calls in your immediate building area. All residents are safe!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...activeAlerts.map((inc) {
                  final incId = inc['id'] ?? 0;
                  final code = inc['incident_code'] ?? 'INC-$incId';
                  final status = inc['status'] ?? 'Pending';
                  final prio = inc['priority'] ?? 'High';
                  final desc = inc['description'] ?? 'Emergency assistance requested';
                  final location = inc['location'] ?? 'Resident Home';
                  final resident = _residentsMap[inc['resident_id']];
                  final resName = resident != null ? resident['full_name'] : 'Resident #${inc['resident_id']}';
                  final resAge = resident != null ? resident['age'] : 'N/A';
                  final responderName = inc['responder_name'];
                  final isIResponding = responderName == user?.fullName;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    borderColor: prio == 'Critical' ? AppColors.statusEmergency : AppColors.statusAlert,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '📍 ~45m Away',
                                style: TextStyle(
                                  color: AppColors.accentTeal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Resident Info
                        Text(
                          'Resident: $resName (Age $resAge)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.accentBlue, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Location: $location',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Emergency Details Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bgDarkInput,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '🚨 Details: "$desc"',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action / Responder Status
                        if (isIResponding)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.statusSafe.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.statusSafe),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.statusSafe, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'You are on your way to help!',
                                  style: TextStyle(
                                    color: AppColors.statusSafe,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (responderName != null)
                          Text(
                            '✓ Active Responder: $responderName (${inc['responder_role'] ?? 'Responder'})',
                            style: const TextStyle(
                              color: AppColors.statusSafe,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _respondingId == incId ? null : () => _handleNeighborRespond(incId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusSafe,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                              label: Text(
                                _respondingId == incId ? 'Accepting...' : '🤝 I Can Help! (On My Way)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // Guidelines Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Neighbor Response Guidelines',
                      style: AppTheme.heading(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentTeal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Check your immediate physical safety before rushing.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('2. Knock or gain entry to provide first aid or comfort.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('3. Confirm if Security or Ambulances have been dispatched.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('4. Keep linked family guardians updated on resident status.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
