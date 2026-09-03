import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_navbar.dart';
import '../widgets/sos_banner.dart';
import 'ai_assistant_screen.dart';
import 'analytics_screen.dart';
import 'guardians_screen.dart';
import 'neighbor_dashboard_screen.dart';
import 'residents_screen.dart';
import 'responders_screen.dart';
import 'settings_screen.dart';
import 'sos_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ApiService _apiService = ApiService();
  String _currentRole = 'resident';
  Map<String, dynamic>? _activeIncident;
  Timer? _incidentCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userRole = ref.read(authProvider).user?.role.toLowerCase() ?? 'resident';
      if (['resident', 'responder', 'security', 'volunteer', 'neighbor', 'guardian', 'caregiver', 'admin'].contains(userRole)) {
        if (userRole == 'security' || userRole == 'volunteer') {
          setState(() => _currentRole = 'responder');
        } else {
          setState(() => _currentRole = userRole);
        }
      }
    });

    _checkForActiveIncidents();
    _incidentCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkForActiveIncidents());
  }

  @override
  void dispose() {
    _incidentCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForActiveIncidents() async {
    try {
      final res = await _apiService.getIncidents();
      final list = res.data is List ? res.data : (res.data['incidents'] ?? []);
      final active = list.firstWhere(
        (i) => i['status'] != 'Resolved',
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _activeIncident = active != null ? Map<String, dynamic>.from(active as Map) : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleResolveIncident() async {
    if (_activeIncident != null && _activeIncident!['id'] != null) {
      try {
        await _apiService.updateIncidentStatus(_activeIncident!['id'], 'Resolved');
        setState(() => _activeIncident = null);
        _checkForActiveIncidents();
      } catch (_) {}
    }
  }

  Widget _buildActivePortalView() {
    switch (_currentRole) {
      case 'resident':
        return const SosScreen();
      case 'responder':
      case 'security':
        return const RespondersScreen();
      case 'neighbor':
      case 'volunteer':
        return const NeighborDashboardScreen();
      case 'guardian':
        return const GuardiansScreen();
      case 'caregiver':
        return const ResidentsScreen();
      case 'admin':
        return const AnalyticsScreen();
      default:
        return const SosScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar matching Navbar.jsx
            AppNavbar(
              currentRole: _currentRole,
              onRoleChanged: (newRole) {
                setState(() => _currentRole = newRole);
              },
              onOpenAI: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                );
              },
              onOpenSettings: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              onLogout: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),

            // Live Alert Banner if incident is pending/active matching SOSBanner.jsx
            if (_activeIncident != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SosBanner(
                  activeIncident: _activeIncident!,
                  onResolve: _handleResolveIncident,
                ),
              ),

            // Dynamic Portal View
            Expanded(
              child: _buildActivePortalView(),
            ),
          ],
        ),
      ),
    );
  }
}
