import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final String activeView;
  final ValueChanged<String>? onViewChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleAI;
  final VoidCallback? onOpenLockScreen;

  const AppNavbar({
    super.key,
    this.user,
    String? activeView,
    String? currentRole,
    ValueChanged<String>? onViewChanged,
    ValueChanged<String>? onRoleChanged,
    this.onLogout,
    this.onOpenSettings,
    VoidCallback? onToggleAI,
    VoidCallback? onOpenAI,
    this.onOpenLockScreen,
  })  : activeView = currentRole ?? activeView ?? 'resident',
        onViewChanged = onRoleChanged ?? onViewChanged,
        onToggleAI = onOpenAI ?? onToggleAI;

  @override
  Size get preferredSize => const Size.fromHeight(115);

  @override
  Widget build(BuildContext context) {
    final userRole = user?.role.toLowerCase() ?? 'resident';
    final isAdmin = userRole == 'admin';

    // Tabs filtered by user permissions or shown for admin
    final allTabs = [
      {'id': 'resident', 'label': 'Resident SOS', 'icon': Icons.emergency_rounded, 'color': AppColors.statusEmergency},
      {'id': 'responder', 'label': 'Responders & Security', 'icon': Icons.shield_rounded, 'color': AppColors.statusSafe},
      {'id': 'neighbor', 'label': 'Neighbor Portal', 'icon': Icons.volunteer_activism_rounded, 'color': AppColors.accentTeal},
      {'id': 'guardian', 'label': 'Guardians', 'icon': Icons.contact_phone_rounded, 'color': AppColors.accentBlue},
      {'id': 'caregiver', 'label': 'Caregiver Roster', 'icon': Icons.people_alt_rounded, 'color': AppColors.accentPurple},
      {'id': 'admin', 'label': 'Admin Analytics', 'icon': Icons.analytics_rounded, 'color': AppColors.accentPurple},
    ];

    List<Map<String, dynamic>> visibleTabs;
    if (isAdmin) {
      visibleTabs = allTabs;
    } else if (userRole == 'security' || userRole == 'responder') {
      visibleTabs = allTabs.where((t) => t['id'] == 'responder' || t['id'] == 'neighbor' || t['id'] == 'resident').toList();
    } else if (userRole == 'volunteer' || userRole == 'neighbor' || userRole == 'neighbour') {
      visibleTabs = allTabs.where((t) => t['id'] == 'neighbor' || t['id'] == 'responder' || t['id'] == 'resident').toList();
    } else if (userRole == 'guardian') {
      visibleTabs = allTabs.where((t) => t['id'] == 'guardian' || t['id'] == 'resident').toList();
    } else if (userRole == 'caregiver') {
      visibleTabs = allTabs.where((t) => t['id'] == 'caregiver' || t['id'] == 'resident').toList();
    } else {
      visibleTabs = allTabs.where((t) => t['id'] == 'resident' || t['id'] == 'neighbor').toList();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20F172A), // rgba(15, 23, 42, 0.95)
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                children: [
                  // CareConnect Brand Gradient Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusEmergency.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Brand Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CareConnect',
                          style: AppTheme.heading(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Emergency Response System',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // AI Assistant Action Button
                  IconButton(
                    tooltip: 'CarePulse AI',
                    onPressed: onToggleAI,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentPurple.withValues(alpha: 0.18),
                      side: BorderSide(color: AppColors.accentPurple.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFC084FC),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Lock Screen Mode Quick Button
                  if (onOpenLockScreen != null) ...[
                    IconButton(
                      tooltip: 'Lock Screen Mode',
                      onPressed: onOpenLockScreen,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.statusEmergency.withValues(alpha: 0.15),
                        side: BorderSide(color: AppColors.statusEmergency.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.all(6),
                      ),
                      icon: const Icon(
                        Icons.screen_lock_portrait_rounded,
                        color: AppColors.statusEmergency,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Settings Button
                  IconButton(
                    tooltip: 'Settings & Profile',
                    onPressed: onOpenSettings,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentTeal.withValues(alpha: 0.15),
                      side: BorderSide(color: AppColors.accentTeal.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.accentTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // User Avatar & Logout Menu
                  PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    color: AppColors.bgSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentTeal, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.accentTeal.withValues(alpha: 0.2),
                        child: Text(
                          (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                    onSelected: (val) {
                      if (val == 'settings' && onOpenSettings != null) {
                        onOpenSettings!();
                      } else if (val == 'logout' && onLogout != null) {
                        onLogout!();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User Account',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'ROLE: ${user?.role.toUpperCase() ?? "RESIDENT"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.statusSafe,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: AppColors.border),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 18, color: AppColors.accentTeal),
                            SizedBox(width: 8),
                            Text('Settings & Diagnostics', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: AppColors.statusEmergency),
                            SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(color: AppColors.statusEmergency)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Quick View Portal Switcher Bar matching website
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0x990F172A),
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Text(
                        'PORTALS:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...visibleTabs.map((tab) {
                      final id = tab['id'] as String;
                      final label = tab['label'] as String;
                      final icon = tab['icon'] as IconData;
                      final isActive = activeView == id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: InkWell(
                          onTap: () {
                            if (onViewChanged != null) {
                              onViewChanged!(id);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.accentTeal.withValues(alpha: 0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive ? AppColors.accentTeal : Colors.transparent,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 13,
                                  color: isActive ? AppColors.accentTeal : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? AppColors.accentTeal : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
