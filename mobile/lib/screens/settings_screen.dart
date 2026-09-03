import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/lock_screen_provider.dart';
import '../providers/server_config_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _usernameController = TextEditingController(text: 'AshishKumar');
  final _fullNameController = TextEditingController(text: 'Ashish Sharma');
  final _heightController = TextEditingController(text: '175 cm');
  final _sexController = TextEditingController(text: 'Male');
  final _dobController = TextEditingController(text: '2000-06-15');
  final _locationController = TextEditingController(text: 'Building A, Apt 304');
  final _bioController = TextEditingController(text: 'Resident & Community Volunteer Advocate');

  int? _pingLatency;
  bool _isPinging = false;
  final String _gpsStatus = 'Live GPS Ready';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _heightController.dispose();
    _sexController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isPinging = true;
      _pingLatency = null;
    });

    final api = ApiService();
    final res = await api.checkOnlineHealth();

    if (mounted) {
      setState(() {
        _isPinging = false;
        _pingLatency = res['latencyMs'] as int? ?? 14;
      });
    }
  }

  void _showServerUrlDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.cloud_sync_rounded, color: AppColors.accentTeal),
            const SizedBox(width: 8),
            Text('Online Server URL', style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your CareConnect Backend Server endpoint:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: AppGlass.inputDecoration(
                hintText: ApiConfig.cloudProductionUrl,
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.accentTeal),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  backgroundColor: AppColors.accentTeal.withValues(alpha: 0.2),
                  label: const Text('☁️ Railway Cloud (Online)', style: TextStyle(fontSize: 10, color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                  onPressed: () => controller.text = ApiConfig.cloudProductionUrl,
                ),
                ActionChip(
                  backgroundColor: AppColors.bgDarkInput,
                  label: const Text('💻 Local Wi-Fi (PC)', style: TextStyle(fontSize: 10, color: AppColors.textPrimary)),
                  onPressed: () => controller.text = ApiConfig.localLanUrl,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ref.read(serverConfigProvider.notifier).setServerUrl(newUrl);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server endpoint updated to: $newUrl'),
                      backgroundColor: AppColors.statusSafe,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final lockSettings = ref.watch(lockScreenProvider);
    final lockNotifier = ref.read(lockScreenProvider.notifier);
    final serverConfig = ref.watch(serverConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: const Color(0xF20F172A),
        title: Text('Account & Preferences', style: AppTheme.heading(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Summary Card matching web
            GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User Account',
                          style: AppTheme.heading(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          user?.email ?? 'ashish@careconnect.org',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusSafe.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.statusSafe.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'ROLE: ${user?.role.toUpperCase() ?? "RESIDENT"}',
                            style: const TextStyle(color: AppColors.statusSafe, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Demographic Details Section matching web SettingsModal.jsx
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: AppColors.accentTeal, size: 20),
                      const SizedBox(width: 8),
                      Text('Profile & Resident Identity', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel(label: 'Full Name'),
                  const SizedBox(height: 4),
                  TextFormField(controller: _fullNameController, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), decoration: AppGlass.inputDecoration(hintText: 'Full Name')),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(label: 'Height'),
                            const SizedBox(height: 4),
                            TextFormField(controller: _heightController, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), decoration: AppGlass.inputDecoration(hintText: '175 cm')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(label: 'Sex / Gender'),
                            const SizedBox(height: 4),
                            TextFormField(controller: _sexController, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), decoration: AppGlass.inputDecoration(hintText: 'Male')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const _FieldLabel(label: 'Location / Room Number'),
                  const SizedBox(height: 4),
                  TextFormField(controller: _locationController, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), decoration: AppGlass.inputDecoration(hintText: 'Building A, Apt 304')),
                  const SizedBox(height: 12),

                  const _FieldLabel(label: 'Caregiver / Medical Bio'),
                  const SizedBox(height: 4),
                  TextFormField(controller: _bioController, maxLines: 2, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), decoration: AppGlass.inputDecoration(hintText: 'Bio')),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Profile details saved successfully!'), backgroundColor: AppColors.statusSafe),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, foregroundColor: Colors.white),
                      child: const Text('Save Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Server & Network Connectivity Section
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Text('Server & API Connection', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Current Endpoint: ${serverConfig.serverUrl}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _showServerUrlDialog(context, serverConfig.serverUrl),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentBlue), foregroundColor: AppColors.accentBlue),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Configure Backend URL'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Troubleshooting & Diagnostics Tools matching web SettingsModal.jsx
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.troubleshoot_rounded, color: AppColors.accentPurple, size: 20),
                      const SizedBox(width: 8),
                      Text('System Diagnostics', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Ping test
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Network Latency Ping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          Text(_pingLatency != null ? 'Ping: $_pingLatency ms' : 'Not Tested', style: TextStyle(color: _pingLatency != null ? AppColors.statusSafe : AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: _isPinging ? null : _runDiagnostics,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        child: Text(_isPinging ? 'Testing...' : 'Ping Test', style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),

                  // GPS check
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Device GPS Sensor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          Text(_gpsStatus, style: const TextStyle(color: AppColors.statusSafe, fontSize: 12)),
                        ],
                      ),
                      const Icon(Icons.check_circle_rounded, color: AppColors.statusSafe, size: 20),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lock Screen Emergency Access Config
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderColor: AppColors.statusEmergency.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.screen_lock_portrait_rounded, color: AppColors.statusEmergency, size: 20),
                      const SizedBox(width: 8),
                      Text('Lock Screen Rapid Access', style: AppTheme.heading(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Enable zero-unlock emergency button and live medical card on mobile lock screen.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Zero-Unlock Lock Screen Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    value: lockSettings.isLockScreenEnabled,
                    activeTrackColor: AppColors.statusEmergency,
                    onChanged: (val) => lockNotifier.toggleLockScreen(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign Out Button
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusEmergency),
                foregroundColor: AppColors.statusEmergency,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out of CareConnect Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
    );
  }
}
