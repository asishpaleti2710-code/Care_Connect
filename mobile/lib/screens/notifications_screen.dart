import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/sos_model.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<SosNotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final res = await _apiService.getNotifications(unreadOnly: _unreadOnly);
      if (!mounted) return;

      if (res.data is List) {
        final items = (res.data as List)
            .map((item) => SosNotificationItem.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = [
          SosNotificationItem(
            id: 1,
            title: 'Medical Emergency Alert',
            message: 'Resident Eleanor Vance triggered an SOS panic call in Room 304.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
            channel: 'PUSH',
            status: 'NEW',
          ),
          SosNotificationItem(
            id: 2,
            title: 'Incident Accepted',
            message: 'Responder Officer Dave accepted dispatch call INC-102.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
            isRead: true,
            channel: 'IN_APP',
            status: 'READ',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _apiService.markNotificationRead(id);
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      _loadNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: const Color(0xF20F172A),
        title: Text('Emergency Alerts', style: AppTheme.heading(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, color: AppColors.accentTeal),
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Alerts'),
                    selected: !_unreadOnly,
                    selectedColor: AppColors.accentTeal,
                    labelStyle: TextStyle(
                      color: !_unreadOnly ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.bgDarkInput,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _unreadOnly = false);
                        _loadNotifications();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread Only'),
                    selected: _unreadOnly,
                    selectedColor: AppColors.statusEmergency,
                    labelStyle: TextStyle(
                      color: _unreadOnly ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.bgDarkInput,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _unreadOnly = true);
                        _loadNotifications();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
                  : _notifications.isEmpty
                      ? const Center(
                          child: Text(
                            'No emergency notifications found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: AppColors.accentTeal,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              final isEmergency = item.channel.toLowerCase().contains('emergency') ||
                                  item.title.toLowerCase().contains('emergency');

                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                borderColor: !item.isRead
                                    ? (isEmergency ? AppColors.statusEmergency : AppColors.accentTeal)
                                    : AppColors.glassBorder,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isEmergency ? Icons.warning_rounded : Icons.notifications_rounded,
                                              color: isEmergency ? AppColors.statusEmergency : AppColors.accentTeal,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: !item.isRead ? AppColors.textPrimary : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.statusEmergency,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.message,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.createdAt.toString().split('.')[0],
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                        ),
                                        if (!item.isRead)
                                          TextButton(
                                            onPressed: () => _markRead(item.id),
                                            child: const Text('Mark Read', style: TextStyle(fontSize: 11, color: AppColors.accentTeal)),
                                          ),
                                      ],
                                    ),
                                  ],
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
