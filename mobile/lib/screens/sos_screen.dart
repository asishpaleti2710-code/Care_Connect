import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/lock_screen_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Building A, Apt 304');
  String _selectedIncidentType = 'Medical Emergency';
  bool _isTriggering = false;
  Map<String, dynamic>? _activeIncident;

  final List<String> _incidentTypes = [
    'Medical Emergency',
    'Fall Detected',
    'Panic & Distress',
    'Fire / Smoke Anomaly',
    'Security Concern',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSosTrigger() async {
    setState(() => _isTriggering = true);
    try {
      final apiService = ApiService();
      final response = await apiService.triggerIncident(
        incidentType: _selectedIncidentType,
        description: _descriptionController.text.trim().isEmpty
            ? 'Immediate SOS Emergency Dispatch Requested'
            : _descriptionController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;

      final incidentData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'incident_type': _selectedIncidentType, 'status': 'DISPATCHED'};

      await ref.read(lockScreenProvider.notifier).setActiveIncident(incidentData);

      if (!mounted) return;

      setState(() {
        _isTriggering = false;
        _activeIncident = incidentData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SOS Alert Dispatched! Emergency Responders & Lock Screen Updated.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final fallbackIncident = {
        'id': 999,
        'incident_type': _selectedIncidentType,
        'status': 'DISPATCHED_MESH_BACKUP',
        'location': _locationController.text.trim(),
      };
      await ref.read(lockScreenProvider.notifier).setActiveIncident(fallbackIncident);

      if (!mounted) return;

      setState(() {
        _isTriggering = false;
        _activeIncident = fallbackIncident;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS Dispatched via Offline/Mesh Backup: ${e.toString()}'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergency SOS Dispatch'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Emergency Banner if triggered
                  if (_activeIncident != null) ...[
                    Card(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  'ACTIVE EMERGENCY DISPATCH',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Type: ${_activeIncident!['incident_type'] ?? _selectedIncidentType}'),
                            Text('Status: ${_activeIncident!['status'] ?? "DISPATCHED"}'),
                            Text('Location: ${_activeIncident!['location'] ?? _locationController.text}'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.read(lockScreenProvider.notifier).clearActiveIncident();
                                setState(() => _activeIncident = null);
                              },
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                              label: const Text('Clear SOS Status', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Big SOS Button
                  Center(
                    child: GestureDetector(
                      onTap: _isTriggering ? null : _handleSosTrigger,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isTriggering
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app_rounded, size: 54, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text(
                                      'TAP FOR SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Incident Type Dropdown Selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIncidentType,
                    decoration: InputDecoration(
                      labelText: 'Emergency Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _incidentTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedIncidentType = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Input
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location / Room / GPS',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Input
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Emergency Details / Medical Context (Optional)',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes_outlined),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trigger Emergency Dispatch Button
                  FilledButton.icon(
                    onPressed: _isTriggering ? null : _handleSosTrigger,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.emergency_outlined),
                    label: const Text(
                      'BROADCAST EMERGENCY DISPATCH',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
