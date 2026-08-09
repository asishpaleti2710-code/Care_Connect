import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/lock_screen_provider.dart';
import '../providers/server_config_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showServerUrlDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Online Server URL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify your CareConnect Online Cloud Server endpoint (e.g. hosted API, cloud domain, or local LAN IP):',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://api.careconnect.app or http://192.168.1.50:8000',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Production Cloud', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'https://api.careconnect.app',
                ),
                ActionChip(
                  label: const Text('Localhost / Tunnel', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://localhost:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
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
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
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
    final serverNotifier = ref.read(serverConfigProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Summary
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'User Account',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Role: ${user?.role.toUpperCase() ?? "RESIDENT"}',
                            style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cloud & Online Server Configuration Section
            Row(
              children: [
                const Icon(Icons.cloud_sync_rounded, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'INTERNET & CLOUD VERSION SETTINGS',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Online Server Status Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: serverConfig.status == ConnectionStatus.connected
                      ? Colors.green.withValues(alpha: 0.5)
                      : (serverConfig.status == ConnectionStatus.offline
                          ? Colors.orangeAccent.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant),
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
                        Row(
                          children: [
                            Icon(
                              serverConfig.status == ConnectionStatus.connected
                                  ? Icons.cloud_done_rounded
                                  : (serverConfig.status == ConnectionStatus.testing
                                      ? Icons.sync_rounded
                                      : Icons.cloud_off_rounded),
                              color: serverConfig.status == ConnectionStatus.connected
                                  ? Colors.green
                                  : (serverConfig.status == ConnectionStatus.testing
                                      ? Colors.blueAccent
                                      : Colors.orangeAccent),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              serverConfig.status == ConnectionStatus.connected
                                  ? 'ONLINE CLOUD CONNECTED'
                                  : (serverConfig.status == ConnectionStatus.testing
                                      ? 'CHECKING CONNECTION...'
                                      : 'OFFLINE / LOCAL STANDBY'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: serverConfig.status == ConnectionStatus.connected
                                    ? Colors.green
                                    : (serverConfig.status == ConnectionStatus.testing
                                        ? Colors.blueAccent
                                        : Colors.orangeAccent),
                              ),
                            ),
                          ],
                        ),
                        if (serverConfig.latencyMs != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${serverConfig.latencyMs}ms',
                              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Endpoint: ${serverConfig.serverUrl}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showServerUrlDialog(context, serverConfig.serverUrl),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Change Endpoint', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final ok = await serverNotifier.testConnection();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? '🟢 Server is Online & Reachable!' : '🔴 Could not connect to Server'),
                                    backgroundColor: ok ? Colors.green : Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.network_check_rounded, size: 16),
                            label: const Text('Test Ping', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              value: serverConfig.isOnlineMode,
              onChanged: (val) => serverNotifier.setOnlineMode(val),
              title: const Text('Cloud Real-Time Sync'),
              subtitle: const Text('Automatically synchronize SOS dispatches & responder GPS across the internet'),
              secondary: const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent),
            ),

            const SizedBox(height: 20),

            // Lock Screen Emergency Access Section Header
            Row(
              children: [
                const Icon(Icons.lock_clock_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'LOCK SCREEN & EMERGENCY ACCESS',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Explanatory Banner
            Card(
              color: Colors.red.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Allows you or first responders to trigger SOS alerts, broadcast GPS, and view vital medical data directly on the lock screen without unlocking the phone.',
                        style: TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lock Screen Controls
            SwitchListTile(
              value: lockSettings.isLockScreenEnabled,
              onChanged: (val) => lockNotifier.toggleLockScreenEnabled(val),
              title: const Text('Direct Lock Screen Display'),
              subtitle: const Text('Appears directly on lock screen without PIN / fingerprint'),
              secondary: const Icon(Icons.screen_lock_portrait_rounded, color: Colors.redAccent),
            ),
            SwitchListTile(
              value: lockSettings.showNotificationWidget,
              onChanged: (val) => lockNotifier.toggleNotificationWidget(val),
              title: const Text('Lock Screen Notification Widget'),
              subtitle: const Text('Sticky quick-action buttons on the locked notification shade'),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            SwitchListTile(
              value: lockSettings.showMedicalIdOnLockScreen,
              onChanged: (val) => lockNotifier.toggleMedicalId(val),
              title: const Text('Lock Screen Medical ID'),
              subtitle: const Text('Display blood group & emergency contacts for paramedics'),
              secondary: const Icon(Icons.badge_outlined, color: Colors.teal),
            ),
            SwitchListTile(
              value: lockSettings.autoWakeScreenOnSos,
              onChanged: (val) => lockNotifier.toggleAutoWake(val),
              title: const Text('Auto-Wake Screen on SOS'),
              subtitle: const Text('Turn on screen immediately when emergency triggers'),
              secondary: const Icon(Icons.flash_on_rounded, color: Colors.orangeAccent),
            ),
            SwitchListTile(
              value: lockSettings.shakeToSosEnabled,
              onChanged: (val) => lockNotifier.toggleShakeToSos(val),
              title: const Text('Shake to Trigger Lock Screen SOS'),
              subtitle: const Text('Shake phone 3 times on lockscreen to start dispatch'),
              secondary: const Icon(Icons.vibration_rounded, color: Colors.purpleAccent),
            ),

            const SizedBox(height: 12),

            // Preview Lock Screen Emergency Hub Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/lockscreen-hub');
                },
                icon: const Icon(Icons.phone_android_rounded, color: Colors.redAccent),
                label: const Text(
                  '📱 PREVIEW LOCK SCREEN EMERGENCY HUB',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // General Notification & Security
            Text(
              'GENERAL PREFERENCES',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Community Push Notifications'),
              subtitle: const Text('Neighborhood alerts & safety broadcasts'),
              secondary: const Icon(Icons.notifications_outlined),
            ),
            SwitchListTile(
              value: true,
              onChanged: (val) {},
              title: const Text('Live GPS Location Sharing'),
              subtitle: const Text('Provide precise responder navigation coordinates'),
              secondary: const Icon(Icons.location_on_outlined),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password security management opened.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
