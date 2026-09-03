import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class RealtimeWebSocketClient {
  static final RealtimeWebSocketClient _instance = RealtimeWebSocketClient._internal();
  factory RealtimeWebSocketClient() => _instance;
  RealtimeWebSocketClient._internal();

  WebSocket? _sosSocket;
  WebSocket? _trackingSocket;
  bool _isConnected = false;
  final _storage = StorageService();

  final _sosEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sosEvents => _sosEventController.stream;

  final _trackingEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get trackingEvents => _trackingEventController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final base = await _storage.getApiBaseUrl() ?? ApiConfig.baseUrl;
      final wsBase = base.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://').replaceAll(RegExp(r'/+$'), '');

      // 1. Connect to SOS Alert Channel
      _sosSocket = await WebSocket.connect('$wsBase/ws/sos').timeout(const Duration(seconds: 5));
      _sosSocket!.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            _sosEventController.add(Map<String, dynamic>.from(data));
          } catch (_) {}
        },
        onError: (err) {
          debugPrint('[WS SOS Error] $err');
          _reconnectLater();
        },
        onDone: () {
          _isConnected = false;
        },
      );

      // 2. Connect to Live Tracking Channel
      _trackingSocket = await WebSocket.connect('$wsBase/ws/tracking').timeout(const Duration(seconds: 5));
      _trackingSocket!.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            _trackingEventController.add(Map<String, dynamic>.from(data));
          } catch (_) {}
        },
        onError: (err) {
          debugPrint('[WS Tracking Error] $err');
        },
      );

      _isConnected = true;
      debugPrint('[CareConnect WebSocket] Connected to real-time telemetry streams.');
    } catch (e) {
      debugPrint('[CareConnect WebSocket] Connection deferred: $e');
      _isConnected = false;
    }
  }

  void _reconnectLater() {
    _isConnected = false;
    Future.delayed(const Duration(seconds: 8), () {
      connect();
    });
  }

  void sendTrackingPing(double latitude, double longitude, {String? role, String? name}) {
    if (_trackingSocket != null && _trackingSocket!.readyState == WebSocket.open) {
      final payload = jsonEncode({
        'type': 'LOCATION_PING',
        'latitude': latitude,
        'longitude': longitude,
        'role': role ?? 'user',
        'name': name ?? 'CareConnect User',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      _trackingSocket!.add(payload);
    }
  }

  void disconnect() {
    _sosSocket?.close();
    _trackingSocket?.close();
    _isConnected = false;
  }
}
