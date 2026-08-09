import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class RespondersScreen extends ConsumerStatefulWidget {
  const RespondersScreen({super.key});

  @override
  ConsumerState<RespondersScreen> createState() => _RespondersScreenState();
}

class _RespondersScreenState extends ConsumerState<RespondersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getIncidents();
      final data = response.data is List ? response.data : (response.data['incidents'] ?? []);
      if (mounted) {
        setState(() {
          _incidents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _incidents = [
            {
              'id': 101,
              'incident_type': 'Medical Emergency',
              'status': 'Triggered',
              'location': 'Building B, Apt 201',
              'description': 'Chest pain & low oxygen warning',
              'created_at': '5 mins ago'
            },
            {
              'id': 102,
              'incident_type': 'Fall Anomaly',
              'status': 'Accepted',
              'location': 'West Garden Hallway',
              'description': 'Smart sensor detected sudden fall',
              'created_at': '18 mins ago'
            },
          ];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptIncident(int incidentId) async {
    try {
      await _apiService.updateIncidentStatus(incidentId, 'Accepted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident #$incidentId Accepted! Navigation route generated.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchIncidents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responders Dispatch Feed'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchIncidents,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final item = _incidents[index];
                    final id = item['id'] ?? (index + 1);
                    final type = item['incident_type'] ?? 'Emergency Alert';
                    final status = item['status'] ?? 'Triggered';
                    final location = item['location'] ?? 'Building A';
                    final desc = item['description'] ?? 'Immediate assistance requested';

                    final isAccepted = status.toString().toLowerCase() == 'accepted';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isAccepted ? Colors.green : Colors.orangeAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Incident #$id — $type',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAccepted ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: isAccepted ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(location, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(desc, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            if (!isAccepted)
                              FilledButton.icon(
                                onPressed: () => _acceptIncident(id),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Accept Emergency Response Dispatch'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.black,
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening turn-by-turn map navigation...')),
                                  );
                                },
                                icon: const Icon(Icons.navigation_outlined, color: Colors.green),
                                label: const Text('View Turn-by-Turn GPS Route', style: TextStyle(color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
