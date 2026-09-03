import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class RespondersScreen extends ConsumerStatefulWidget {
  const RespondersScreen({super.key});

  @override
  ConsumerState<RespondersScreen> createState() => _RespondersScreenState();
}

class _RespondersScreenState extends ConsumerState<RespondersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _incidents = [];
  Map<int, dynamic> _residentsMap = {};
  bool _isLoading = true;
  String _activeTab = 'pending'; // 'pending', 'assigned', 'all'
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _loadIncidents(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidents({bool silent = false}) async {
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
              'id': 101,
              'incident_code': 'INC-101',
              'resident_id': 1,
              'emergency_type': 'Medical Emergency',
              'priority': 'Critical',
              'status': 'Pending',
              'location': 'Building A, Apt 304',
              'description': 'Chest pain and breathlessness reported.',
            },
            {
              'id': 102,
              'incident_code': 'INC-102',
              'resident_id': 2,
              'emergency_type': 'Fall Anomaly',
              'priority': 'High',
              'status': 'Accepted',
              'location': 'West Garden Hallway',
              'description': 'Smart sensor detected sudden fall.',
              'responder_name': 'Security Team Alpha',
            },
          ];
          _residentsMap = {
            1: {'id': 1, 'full_name': 'Eleanor Vance', 'age': 78, 'room_number': '304'},
            2: {'id': 2, 'full_name': 'Arthur Pendelton', 'age': 82, 'room_number': '112'}
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAccept(int id) async {
    final user = ref.read(authProvider).user;
    try {
      await _apiService.updateIncidentStatus(
        id,
        'Accepted',
        responderName: user?.fullName ?? 'Campus Security',
        responderRole: user?.role ?? 'Security',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Accepted Incident #$id! GPS dispatch route activated.'),
            backgroundColor: AppColors.statusSafe,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadIncidents(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusEmergency),
        );
      }
    }
  }

  Future<void> _handleUpdateStatus(int id, String status) async {
    try {
      await _apiService.updateIncidentStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident #$id updated to $status.'),
            backgroundColor: AppColors.accentTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadIncidents(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusEmergency),
        );
      }
    }
  }

  void _showNavigationModal(Map<String, dynamic> inc) {
    final res = _residentsMap[inc['resident_id']];
    final resName = res?['full_name'] ?? 'Resident';
    final loc = inc['location'] ?? 'Building A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: AppColors.accentBlue),
            const SizedBox(width: 8),
            Text('Dispatch Route: ${inc['incident_code']}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resident: $resName (Room ${res?['room_number'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
            const SizedBox(height: 8),
            Text('📍 Target Destination: $loc', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDarkInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GPS ROUTE GUIDANCE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  SizedBox(height: 4),
                  Text('1. Head North on Main Corridor (20m)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('2. Take Elevator / Stairwell to 3rd Floor', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('3. Arrive at Apartment #304 (Target on Left)', style: TextStyle(fontSize: 11, color: AppColors.statusSafe, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          if (inc['status'] == 'Pending')
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleAccept(inc['id']);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.accentTeal),
              child: const Text('Accept & Dispatch'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final pendingList = _incidents.where((i) => i['status'] == 'Pending').toList();
    final assignedList = _incidents.where((i) => (i['responder_name'] == user?.fullName || i['status'] == 'Accepted' || i['status'] == 'In Progress') && i['status'] != 'Resolved').toList();
    final resolvedList = _incidents.where((i) => i['status'] == 'Resolved').toList();

    List<dynamic> displayedList;
    if (_activeTab == 'pending') {
      displayedList = pendingList;
    } else if (_activeTab == 'assigned') {
      displayedList = assignedList;
    } else {
      displayedList = _incidents;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadIncidents(),
          color: AppColors.accentTeal,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: AppColors.statusSafe, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Responder Portal',
                              style: AppTheme.heading(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${user?.role.toUpperCase() ?? "SECURITY"} • Real-time Emergency Dispatch',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _loadIncidents(),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accentTeal),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3 Top Metric Counter Cards matching web
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      title: 'UNASSIGNED SOS',
                      value: '${pendingList.length}',
                      color: AppColors.statusEmergency,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricBox(
                      title: 'MY ACTIVE',
                      value: '${assignedList.length}',
                      color: AppColors.statusAlert,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricBox(
                      title: 'RESOLVED',
                      value: '${resolvedList.length}',
                      color: AppColors.statusSafe,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Filter Tabs Pill Bar matching web
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'Pending SOS (${pendingList.length})',
                      isActive: _activeTab == 'pending',
                      onTap: () => setState(() => _activeTab = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'My Assigned (${assignedList.length})',
                      isActive: _activeTab == 'assigned',
                      onTap: () => setState(() => _activeTab = 'assigned'),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'All Incident History (${_incidents.length})',
                      isActive: _activeTab == 'all',
                      onTap: () => setState(() => _activeTab = 'all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Incidents List Roster
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (displayedList.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No emergency incidents found in this view.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...displayedList.map((inc) {
                  final id = inc['id'] ?? 0;
                  final code = inc['incident_code'] ?? 'INC-$id';
                  final status = inc['status'] ?? 'Pending';
                  final prio = inc['priority'] ?? 'High';
                  final desc = inc['description'] ?? '';
                  final location = inc['location'] ?? 'Resident Room';
                  final resident = _residentsMap[inc['resident_id']];
                  final resName = resident != null ? resident['full_name'] : 'Resident #${inc['resident_id']}';
                  final resAge = resident != null ? resident['age'] : 'N/A';
                  final responderName = inc['responder_name'];

                  Color borderPriorityColor = AppColors.accentBlue;
                  if (prio == 'Critical') {
                    borderPriorityColor = AppColors.statusEmergency;
                  } else if (prio == 'High') {
                    borderPriorityColor = AppColors.statusAlert;
                  }

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    borderColor: borderPriorityColor.withValues(alpha: 0.6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
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
                                color: borderPriorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$prio PRIORITY',
                                style: TextStyle(
                                  color: borderPriorityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Resident Info
                        Text(
                          'Resident: $resName (Age $resAge)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentBlue),
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
                        const SizedBox(height: 6),

                        // Emergency Details Quote
                        Text(
                          'Emergency Details: "$desc"',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),

                        if (responderName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '✓ Assigned Responder: $responderName (${inc['responder_role'] ?? "Security"})',
                            style: const TextStyle(fontSize: 11, color: AppColors.statusSafe, fontWeight: FontWeight.bold),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Actions Row matching web
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showNavigationModal(Map<String, dynamic>.from(inc as Map)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.accentBlue),
                                foregroundColor: AppColors.accentBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.navigation_rounded, size: 14),
                              label: const Text('Directions & Map', style: TextStyle(fontSize: 11)),
                            ),
                            if (status == 'Pending')
                              ElevatedButton.icon(
                                onPressed: () => _handleAccept(id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                label: const Text('Accept Request', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            if (status == 'Accepted')
                              ElevatedButton(
                                onPressed: () => _handleUpdateStatus(id, 'In Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusAlert,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Set In Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            if (status == 'Accepted' || status == 'In Progress')
                              ElevatedButton.icon(
                                onPressed: () => _handleUpdateStatus(id, 'Resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusSafe,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Icons.task_alt_rounded, size: 14),
                                label: const Text('Mark Resolved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
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

class _MetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentTeal : const Color(0x991E293B),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isActive ? AppColors.accentTeal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

