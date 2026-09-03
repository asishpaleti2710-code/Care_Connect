import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _analytics;
  List<dynamic> _residents = [];
  List<dynamic> _incidents = [];
  bool _isLoading = true;

  String _incidentFilter = 'all'; // 'all', 'pending', 'active', 'resolved'
  String _categoryFilter = 'all';
  String _userStatusFilter = 'all'; // 'all', 'safe', 'alert', 'emergency'
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _loadAdminData(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final anRes = await _apiService.getAnalytics();
      final resRes = await _apiService.getResidents();
      final incRes = await _apiService.getIncidents();

      final resList = resRes.data is List ? resRes.data : (resRes.data['residents'] ?? []);
      final incList = incRes.data is List ? incRes.data : (incRes.data['incidents'] ?? []);

      if (mounted) {
        setState(() {
          _analytics = anRes.data is Map ? Map<String, dynamic>.from(anRes.data) : null;
          _residents = resList;
          _incidents = incList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _incidents = [
            {'id': 1, 'incident_code': 'INC-001', 'emergency_type': 'Medical Emergency', 'status': 'Pending', 'description': 'Severe chest tightness'},
            {'id': 2, 'incident_code': 'INC-002', 'emergency_type': 'Fall Anomaly', 'status': 'Accepted', 'description': 'Sudden fall in hallway', 'responder_name': 'Officer Dave'},
            {'id': 3, 'incident_code': 'INC-003', 'emergency_type': 'Fire / Smoke', 'status': 'Resolved', 'description': 'Kitchen smoke detected and cleared'},
          ];
          _residents = [
            {'id': 1, 'full_name': 'Eleanor Vance', 'age': 78, 'blood_group': 'O+', 'status': 'safe', 'room_number': '304'},
            {'id': 2, 'full_name': 'Arthur Pendelton', 'age': 82, 'blood_group': 'A+', 'status': 'alert', 'room_number': '112'},
            {'id': 3, 'full_name': 'Margaret Lin', 'age': 74, 'blood_group': 'B+', 'status': 'safe', 'room_number': '205'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResolve(int id) async {
    try {
      await _apiService.updateIncidentStatus(id, 'Resolved');
      _loadAdminData(silent: true);
    } catch (_) {}
  }

  Future<void> _handleAccept(int id) async {
    try {
      await _apiService.updateIncidentStatus(id, 'Accepted', responderName: 'Admin Desk', responderRole: 'Command Center');
      _loadAdminData(silent: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncidents = _incidents.where((inc) {
      final status = (inc['status'] ?? '').toString();
      final type = (inc['emergency_type'] ?? '').toString();
      final code = (inc['incident_code'] ?? '').toString().toLowerCase();
      final desc = (inc['description'] ?? '').toString().toLowerCase();

      final matchesStatus = _incidentFilter == 'all' ||
          (_incidentFilter == 'pending' && status == 'Pending') ||
          (_incidentFilter == 'active' && (status == 'Accepted' || status == 'In Progress')) ||
          (_incidentFilter == 'resolved' && status == 'Resolved');

      final matchesCategory = _categoryFilter == 'all' || type == _categoryFilter;
      final matchesSearch = _searchQuery.isEmpty || code.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesCategory && matchesSearch;
    }).toList();

    final filteredResidents = _residents.where((r) {
      final st = (r['status'] ?? 'safe').toString().toLowerCase();
      final name = (r['full_name'] ?? '').toString().toLowerCase();
      final matchesStatus = _userStatusFilter == 'all' || st == _userStatusFilter;
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    final resolvedCount = _incidents.where((i) => i['status'] == 'Resolved').length;
    final activeCount = _incidents.where((i) => i['status'] != 'Resolved').length;
    final avgResponse = _analytics?['avg_response_time_minutes'] ?? 2.4;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadAdminData(),
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
                            const Icon(Icons.analytics_rounded, color: AppColors.accentPurple, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Control Center',
                              style: AppTheme.heading(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Live Incident Audits & System Response Metrics',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _loadAdminData(),
                    icon: const Icon(Icons.sync_rounded, color: AppColors.accentTeal),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4 Live Metric Cards matching web
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'TOTAL CALLS',
                      value: '${_incidents.length}',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'RESOLVED',
                      value: '$resolvedCount',
                      color: AppColors.statusSafe,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'PENDING / ACTIVE',
                      value: '$activeCount',
                      color: AppColors.statusAlert,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'AVG RESPONSE',
                      value: '$avgResponse m',
                      color: const Color(0xFFC084FC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Filter Tabs List matching web
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Category Filters',
                      style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentTeal),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CategoryChip(
                          label: 'All Categories (${_incidents.length})',
                          isSelected: _categoryFilter == 'all',
                          onTap: () => setState(() => _categoryFilter = 'all'),
                        ),
                        _CategoryChip(
                          label: 'Medical Emergency',
                          isSelected: _categoryFilter == 'Medical Emergency',
                          onTap: () => setState(() => _categoryFilter = _categoryFilter == 'Medical Emergency' ? 'all' : 'Medical Emergency'),
                        ),
                        _CategoryChip(
                          label: 'Fall Anomaly',
                          isSelected: _categoryFilter == 'Fall Anomaly',
                          onTap: () => setState(() => _categoryFilter = _categoryFilter == 'Fall Anomaly' ? 'all' : 'Fall Anomaly'),
                        ),
                        _CategoryChip(
                          label: 'Fire / Smoke',
                          isSelected: _categoryFilter == 'Fire / Smoke',
                          onTap: () => setState(() => _categoryFilter = _categoryFilter == 'Fire / Smoke' ? 'all' : 'Fire / Smoke'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Executive Incident Audit Roster
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Executive Incident Audit Roster',
                    style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Bar
              TextField(
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: AppGlass.inputDecoration(
                  hintText: 'Filter incidents by code, details...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 10),

              // Status Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusPill(
                      label: 'All (${_incidents.length})',
                      isSelected: _incidentFilter == 'all',
                      onTap: () => setState(() => _incidentFilter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _StatusPill(
                      label: 'Pending (${_incidents.where((i) => i['status'] == 'Pending').length})',
                      isSelected: _incidentFilter == 'pending',
                      onTap: () => setState(() => _incidentFilter = 'pending'),
                    ),
                    const SizedBox(width: 6),
                    _StatusPill(
                      label: 'Active (${_incidents.where((i) => i['status'] == 'Accepted' || i['status'] == 'In Progress').length})',
                      isSelected: _incidentFilter == 'active',
                      onTap: () => setState(() => _incidentFilter = 'active'),
                    ),
                    const SizedBox(width: 6),
                    _StatusPill(
                      label: 'Resolved ($resolvedCount)',
                      isSelected: _incidentFilter == 'resolved',
                      onTap: () => setState(() => _incidentFilter = 'resolved'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Incidents Feed
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (filteredIncidents.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(28),
                  child: Center(child: Text('No incidents match the filter.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                )
              else
                ...filteredIncidents.map((inc) {
                  final code = inc['incident_code'] ?? 'INC';
                  final status = inc['status'] ?? 'Pending';
                  final type = inc['emergency_type'] ?? 'Emergency';
                  final desc = inc['description'] ?? '';
                  final responderName = inc['responder_name'];

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                const SizedBox(width: 6),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                            Text(type, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                        if (responderName != null) ...[
                          const SizedBox(height: 4),
                          Text('Assigned: $responderName', style: const TextStyle(fontSize: 11, color: AppColors.statusSafe, fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'Pending') ...[
                              FilledButton(
                                onPressed: () => _handleAccept(inc['id']),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentTeal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Accept', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (status != 'Resolved') ...[
                              OutlinedButton(
                                onPressed: () => _handleResolve(inc['id']),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.statusSafe),
                                  foregroundColor: AppColors.statusSafe,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Resolve', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Registered Residents Roster Section matching web
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Residents (${filteredResidents.length})',
                    style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Filter Pills for Residents
              Row(
                children: [
                  _StatusPill(
                    label: 'All',
                    isSelected: _userStatusFilter == 'all',
                    onTap: () => setState(() => _userStatusFilter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Safe',
                    isSelected: _userStatusFilter == 'safe',
                    onTap: () => setState(() => _userStatusFilter = 'safe'),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Alert',
                    isSelected: _userStatusFilter == 'alert',
                    onTap: () => setState(() => _userStatusFilter = 'alert'),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Emergency',
                    isSelected: _userStatusFilter == 'emergency',
                    onTap: () => setState(() => _userStatusFilter = 'emergency'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...filteredResidents.map((r) {
                final name = r['full_name'] ?? 'Resident';
                final age = r['age'] ?? '75';
                final room = r['room_number'] ?? 'N/A';
                final st = (r['status'] ?? 'safe').toString();

                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Age $age • Blood ${r['blood_group'] ?? "O+"} • Room $room', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                      StatusBadge.fromStatus(st),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color == AppColors.textPrimary ? AppColors.textSecondary : color,
              letterSpacing: 0.3,
            ),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.2) : const Color(0x990F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFFC084FC) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTeal : const Color(0x991E293B),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.accentTeal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

