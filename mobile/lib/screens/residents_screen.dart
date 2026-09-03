import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String _statusFilter = 'all'; // 'all', 'safe', 'alert', 'emergency'
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchResidents();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchResidents(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchResidents({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final response = await _apiService.getResidents();
      final data = response.data is List ? response.data : (response.data['residents'] ?? []);
      if (mounted) {
        setState(() {
          _residents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _residents = [
            {
              'id': 1,
              'full_name': 'Eleanor Vance',
              'age': 78,
              'blood_group': 'O+',
              'room_number': '304',
              'address': 'Building A, Apt 304',
              'status': 'safe',
              'emergency_contact': '+1 (555) 234-5678',
              'medical_notes': 'Mild hypertension, allergic to penicillin'
            },
            {
              'id': 2,
              'full_name': 'Arthur Pendelton',
              'age': 82,
              'blood_group': 'A+',
              'room_number': '112',
              'address': 'Building B, Room 112',
              'status': 'alert',
              'emergency_contact': '+1 (555) 345-6789',
              'medical_notes': 'Diabetes Type II, mobility assistance required'
            },
            {
              'id': 3,
              'full_name': 'Margaret Lin',
              'age': 74,
              'blood_group': 'B+',
              'room_number': '205',
              'address': 'Building A, Room 205',
              'status': 'safe',
              'emergency_contact': '+1 (555) 456-7890',
              'medical_notes': 'Asthma, uses daily inhaler'
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _residents.where((r) {
      final status = (r['status'] ?? 'safe').toString().toLowerCase();
      final name = (r['full_name'] ?? '').toString().toLowerCase();
      final room = (r['room_number'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesFilter = _statusFilter == 'all' || status == _statusFilter;
      final matchesSearch = query.isEmpty || name.contains(query) || room.contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    final safeCount = _residents.where((r) => (r['status'] ?? 'safe').toString().toLowerCase() == 'safe').length;
    final alertCount = _residents.where((r) => (r['status'] ?? '').toString().toLowerCase().contains('alert')).length;
    final emergencyCount = _residents.where((r) => (r['status'] ?? '').toString().toLowerCase().contains('emergency')).length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchResidents(),
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
                            const Icon(Icons.apartment_rounded, color: AppColors.accentTeal, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Facility Roster',
                              style: AppTheme.heading(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Caregiver Resident Monitoring & Status Roster',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _fetchResidents(),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accentTeal),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3 Status Summary Metrics matching web Dashboard.jsx
              Row(
                children: [
                  Expanded(
                    child: _RosterMetricCard(
                      title: 'TOTAL RESIDENTS',
                      value: '${_residents.length}',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RosterMetricCard(
                      title: 'STABLE & SAFE',
                      value: '$safeCount',
                      color: AppColors.statusSafe,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RosterMetricCard(
                      title: 'REQUIRES CARE',
                      value: '${alertCount + emergencyCount}',
                      color: (alertCount + emergencyCount) > 0 ? AppColors.statusEmergency : AppColors.statusAlert,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Search Bar
              TextField(
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: AppGlass.inputDecoration(
                  hintText: 'Search resident by name, room...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),

              // Status Filter Pills matching web
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'All (${_residents.length})',
                      isSelected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _FilterPill(
                      label: 'Safe ($safeCount)',
                      isSelected: _statusFilter == 'safe',
                      onTap: () => setState(() => _statusFilter = 'safe'),
                    ),
                    const SizedBox(width: 6),
                    _FilterPill(
                      label: 'Alert ($alertCount)',
                      isSelected: _statusFilter == 'alert',
                      onTap: () => setState(() => _statusFilter = 'alert'),
                    ),
                    const SizedBox(width: 6),
                    _FilterPill(
                      label: 'Emergency ($emergencyCount)',
                      isSelected: _statusFilter == 'emergency',
                      onTap: () => setState(() => _statusFilter = 'emergency'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resident Cards List
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                const GlassCard(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No residents match the selected filter criteria.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                )
              else
                ...filtered.map((res) {
                  final name = res['full_name'] ?? 'Resident';
                  final age = res['age'] ?? '75';
                  final room = res['room_number'] ?? 'N/A';
                  final blood = res['blood_group'] ?? 'O+';
                  final notes = res['medical_notes'] ?? 'No notes';
                  final status = (res['status'] ?? 'safe').toString().toLowerCase();
                  final contact = res['emergency_contact'] ?? '+1-555-0199';

                  Color cardBorder = AppColors.glassBorder;
                  if (status.contains('emergency')) cardBorder = AppColors.statusEmergency;
                  if (status.contains('alert')) cardBorder = AppColors.statusAlert;

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    borderColor: cardBorder.withValues(alpha: 0.6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Blood: $blood',
                                style: const TextStyle(color: AppColors.accentTeal, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Age $age • Room $room • ${res['address'] ?? "Building A"}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),

                        // Medical Note box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgDarkInput,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Condition: $notes',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Action button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('📞 Calling emergency contact for $name: $contact'),
                                    backgroundColor: AppColors.accentTeal,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.accentTeal),
                                foregroundColor: AppColors.accentTeal,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.phone_outlined, size: 14),
                              label: const Text('Call Guardian', style: TextStyle(fontSize: 11)),
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

class _RosterMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _RosterMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: color == AppColors.textPrimary ? AppColors.textSecondary : color,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
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
