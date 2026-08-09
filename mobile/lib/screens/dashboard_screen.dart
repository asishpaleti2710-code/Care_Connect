import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/lock_screen_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authProvider);
    final lockSettings = ref.watch(lockScreenProvider);
    final user = authState.user;

    int crossAxisCount = 2;
    if (screenWidth > 1100) {
      crossAxisCount = 4;
    } else if (screenWidth > 700) {
      crossAxisCount = 3;
    }

    final dashboardItems = [
      _DashboardCardData(
        title: 'SOS Emergency',
        subtitle: 'Trigger immediate dispatch',
        icon: Icons.emergency_rounded,
        color: colorScheme.error,
        onTap: () => Navigator.pushNamed(context, '/sos'),
      ),
      _DashboardCardData(
        title: 'Lock Screen Hub',
        subtitle: 'Zero-unlock rapid controls',
        icon: Icons.screen_lock_portrait_rounded,
        color: Colors.redAccent,
        onTap: () => Navigator.pushNamed(context, '/lockscreen-hub'),
      ),
      _DashboardCardData(
        title: 'Maps & GPS',
        subtitle: 'Live navigation & location',
        icon: Icons.map_rounded,
        color: Colors.blueAccent,
        onTap: () => Navigator.pushNamed(context, '/maps'),
      ),
      _DashboardCardData(
        title: 'CarePulse AI',
        subtitle: 'Medical triage & notes',
        icon: Icons.psychology_rounded,
        color: Colors.purpleAccent,
        onTap: () => Navigator.pushNamed(context, '/ai-assistant'),
      ),
      _DashboardCardData(
        title: 'Residents',
        subtitle: 'Resident profiles & vitals',
        icon: Icons.people_alt_rounded,
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/residents'),
      ),
      _DashboardCardData(
        title: 'Responders',
        subtitle: 'Security & volunteer feed',
        icon: Icons.shield_rounded,
        color: Colors.orangeAccent,
        onTap: () => Navigator.pushNamed(context, '/responders'),
      ),
      _DashboardCardData(
        title: 'Guardians',
        subtitle: 'Family alert contacts',
        icon: Icons.contact_phone_rounded,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/guardians'),
      ),
      _DashboardCardData(
        title: 'Analytics',
        subtitle: 'Response time metrics',
        icon: Icons.analytics_rounded,
        color: Colors.indigoAccent,
        onTap: () => Navigator.pushNamed(context, '/analytics'),
      ),
      _DashboardCardData(
        title: 'Settings',
        subtitle: 'Lock screen & preferences',
        icon: Icons.settings_rounded,
        color: Colors.blueGrey,
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
    ];

    final initialLetter = (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('CareConnect', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open Lock Screen Emergency Mode',
            icon: const Icon(Icons.screen_lock_portrait_rounded, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushNamed(context, '/lockscreen-hub');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency notification system active')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initialLetter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else if (value == 'lockscreen') {
                if (context.mounted) {
                  Navigator.pushNamed(context, '/lockscreen-hub');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'User Account',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lockscreen',
                child: Row(
                  children: [
                    Icon(Icons.screen_lock_portrait_rounded, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Lock Screen Mode', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.fullName ?? "Member"}!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Role: ${user?.role.toUpperCase() ?? "RESIDENT"} • Network status: Active',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Lock Screen Emergency Quick Bar
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/lockscreen-hub'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.screen_lock_portrait_rounded, color: Colors.redAccent, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Lock Screen Quick Access',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.verified, color: Colors.redAccent, size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lockSettings.isLockScreenEnabled
                                  ? 'Active • Manage SOS & Medical ID directly on lock screen'
                                  : 'Disabled • Tap to configure zero-unlock emergency access',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Dashboard Modules',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Responsive Cards Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dashboardItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                size: 28,
                                color: item.color,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _DashboardCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
