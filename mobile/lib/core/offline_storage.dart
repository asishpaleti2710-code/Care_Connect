import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class OfflineStorageManager {
  static const _storage = FlutterSecureStorage();

  static const String _keyCachedIncidents = 'careconnect_cached_incidents';
  static const String _keyQueuedSos = 'careconnect_queued_sos_alerts';
  static const String _keyUserProfile = 'careconnect_cached_user_profile';
  static const String _keyLastSync = 'careconnect_last_sync_timestamp';

  /// Save active emergency incidents to local secure cache
  static Future<void> cacheIncidents(List<dynamic> incidents) async {
    try {
      final jsonString = jsonEncode(incidents);
      await _storage.write(key: _keyCachedIncidents, value: jsonString);
      await _storage.write(
        key: _keyLastSync,
        value: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Retrieve cached emergency incidents
  static Future<List<Map<String, dynamic>>> getCachedIncidents() async {
    try {
      final data = await _storage.read(key: _keyCachedIncidents);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Queue an SOS emergency alert created while offline
  static Future<void> queueOfflineSos({
    required String category,
    String? message,
    double? latitude,
    double? longitude,
    String priority = 'CRITICAL',
  }) async {
    try {
      final currentQueue = await getQueuedSosAlerts();
      final newItem = {
        'temp_id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
        'category': category,
        'message': message ?? 'Emergency alert dispatched while offline',
        'latitude': latitude,
        'longitude': longitude,
        'priority': priority,
        'queued_at': DateTime.now().toUtc().toIso8601String(),
      };
      currentQueue.add(newItem);
      await _storage.write(key: _keyQueuedSos, value: jsonEncode(currentQueue));
    } catch (_) {}
  }

  /// Retrieve all offline-queued SOS alerts
  static Future<List<Map<String, dynamic>>> getQueuedSosAlerts() async {
    try {
      final data = await _storage.read(key: _keyQueuedSos);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Sync all offline queued SOS alerts to the backend once connectivity returns
  static Future<int> syncOfflineAlerts(ApiService apiService) async {
    final queued = await getQueuedSosAlerts();
    if (queued.isEmpty) return 0;

    int syncedCount = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final alert in queued) {
      try {
        final resp = await apiService.createSosAlert(
          category: alert['category'] ?? 'Medical Emergency',
          message: '${alert['message']} [Synced from Offline Queue: ${alert['queued_at']}]',
          latitude: alert['latitude'],
          longitude: alert['longitude'],
          priority: alert['priority'] ?? 'CRITICAL',
        );
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          syncedCount++;
        } else {
          remaining.add(alert);
        }
      } catch (_) {
        remaining.add(alert);
      }
    }

    await _storage.write(key: _keyQueuedSos, value: jsonEncode(remaining));
    return syncedCount;
  }

  /// Cache user profile for offline display
  static Future<void> cacheUserProfile(Map<String, dynamic> user) async {
    try {
      await _storage.write(key: _keyUserProfile, value: jsonEncode(user));
    } catch (_) {}
  }

  /// Get cached user profile
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final data = await _storage.read(key: _keyUserProfile);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
    } catch (_) {}
    return null;
  }

  /// Get last sync timestamp
  static Future<String?> getLastSyncTime() async {
    return await _storage.read(key: _keyLastSync);
  }
}
