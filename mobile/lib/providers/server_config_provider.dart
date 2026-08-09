import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum ConnectionStatus { idle, testing, connected, offline, error }

class ServerConfigState {
  final String serverUrl;
  final bool isOnlineMode;
  final ConnectionStatus status;
  final int? latencyMs;
  final String? statusMessage;

  const ServerConfigState({
    required this.serverUrl,
    this.isOnlineMode = true,
    this.status = ConnectionStatus.idle,
    this.latencyMs,
    this.statusMessage,
  });

  ServerConfigState copyWith({
    String? serverUrl,
    bool? isOnlineMode,
    ConnectionStatus? status,
    int? latencyMs,
    String? statusMessage,
  }) {
    return ServerConfigState(
      serverUrl: serverUrl ?? this.serverUrl,
      isOnlineMode: isOnlineMode ?? this.isOnlineMode,
      status: status ?? this.status,
      latencyMs: latencyMs ?? this.latencyMs,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class ServerConfigNotifier extends StateNotifier<ServerConfigState> {
  final StorageService _storageService;
  final ApiService _apiService;

  ServerConfigNotifier({
    StorageService? storageService,
    ApiService? apiService,
  })  : _storageService = storageService ?? StorageService(),
        _apiService = apiService ?? ApiService(),
        super(ServerConfigState(serverUrl: ApiConfig.baseUrl)) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final savedUrl = await _storageService.getApiBaseUrl();
    final isOnline = await _storageService.getOnlineMode();
    final activeUrl = savedUrl ?? ApiConfig.baseUrl;

    state = state.copyWith(
      serverUrl: activeUrl,
      isOnlineMode: isOnline,
    );

    // Initial silent ping test
    await testConnection(activeUrl);
  }

  Future<void> setServerUrl(String newUrl) async {
    final cleanUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    await _storageService.saveApiBaseUrl(cleanUrl);
    state = state.copyWith(serverUrl: cleanUrl);
    await testConnection(cleanUrl);
  }

  Future<void> setOnlineMode(bool isOnline) async {
    await _storageService.saveOnlineMode(isOnline);
    state = state.copyWith(isOnlineMode: isOnline);
  }

  Future<void> resetToDefault() async {
    final defaultUrl = ApiConfig.baseUrl;
    await _storageService.saveApiBaseUrl(defaultUrl);
    state = state.copyWith(serverUrl: defaultUrl);
    await testConnection(defaultUrl);
  }

  Future<bool> testConnection([String? testUrl]) async {
    final targetUrl = testUrl ?? state.serverUrl;
    state = state.copyWith(status: ConnectionStatus.testing, statusMessage: 'Testing connection...');

    final result = await _apiService.checkOnlineHealth(targetUrl);
    final isOnline = result['isOnline'] == true;
    final latency = result['latencyMs'] as int?;

    if (isOnline) {
      state = state.copyWith(
        status: ConnectionStatus.connected,
        latencyMs: latency,
        statusMessage: 'Connected • ${latency}ms latency',
      );
      return true;
    } else {
      state = state.copyWith(
        status: ConnectionStatus.offline,
        latencyMs: latency,
        statusMessage: 'Offline / Unreachable (${result['error'] ?? 'Connection timed out'})',
      );
      return false;
    }
  }
}

final serverConfigProvider = StateNotifierProvider<ServerConfigNotifier, ServerConfigState>((ref) {
  return ServerConfigNotifier();
});
