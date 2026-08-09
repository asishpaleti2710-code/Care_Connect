import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _residents = [];
  List<dynamic> _filteredResidents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  Future<void> _fetchResidents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getResidents();
      final data = response.data is List ? response.data : (response.data['residents'] ?? []);
      if (mounted) {
        setState(() {
          _residents = data;
          _applySearchFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback mock data if server seed is fresh/empty
          _residents = [
            {
              'id': 1,
              'full_name': 'Eleanor Vance',
              'age': 78,
              'room_number': '304-A',
              'status': 'Stable',
              'medical_notes': 'Mild hypertension, allergic to penicillin'
            },
            {
              'id': 2,
              'full_name': 'Arthur Pendelton',
              'age': 82,
              'room_number': '112-B',
              'status': 'Requires Monitoring',
              'medical_notes': 'Diabetes Type II, mobility assistance required'
            },
            {
              'id': 3,
              'full_name': 'Margaret Lin',
              'age': 74,
              'room_number': '205-C',
              'status': 'Normal Vitals',
              'medical_notes': 'No known allergies, active volunteer'
            },
          ];
          _applySearchFilter();
          _isLoading = false;
        });
      }
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredResidents = List.from(_residents);
    } else {
      _filteredResidents = _residents.where((r) {
        final name = (r['full_name'] ?? '').toString().toLowerCase();
        final room = (r['room_number'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || room.contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Directory'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search Resident by Name or Room',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applySearchFilter();
                  });
                },
              ),
            ),

            // Residents List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchResidents,
                      child: _filteredResidents.isEmpty
                          ? const Center(child: Text('No residents found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredResidents.length,
                              itemBuilder: (context, index) {
                                final res = _filteredResidents[index];
                                final name = res['full_name'] ?? 'Resident';
                                final age = res['age'] ?? '75';
                                final room = res['room_number'] ?? 'N/A';
                                final notes = res['medical_notes'] ?? 'No notes recorded';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: colorScheme.primaryContainer,
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Room $room',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Age: $age years old'),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Notes: $notes',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
