import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storageService;

  ApiService({StorageService? storageService, String? baseUrl})
      : _storageService = storageService ?? StorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? customUrl = await _storageService.getApiBaseUrl();

          // Auto-clean any local, emulator, or invalid URLs so physical devices never get trapped
          final isLocalOrInvalid = customUrl != null && (
            customUrl.contains('localhost') ||
            customUrl.contains('127.0.0.1') ||
            customUrl.contains('10.0.2.2') ||
            customUrl.contains('192.168.') ||
            customUrl.contains('api.careconnect.app') ||
            customUrl.trim().isEmpty
          );

          if (isLocalOrInvalid) {
            developer.log(
              '[NETWORK SANITIZER] Detected local/unreachable URL ($customUrl). Resetting to Cloud Production URL.',
              name: 'CareConnect.Network',
            );
            await _storageService.saveApiBaseUrl(ApiConfig.cloudProductionUrl);
            customUrl = ApiConfig.cloudProductionUrl;
          }

          if (customUrl != null && customUrl.trim().isNotEmpty) {
            options.baseUrl = customUrl.trim();
          } else {
            options.baseUrl = ApiConfig.cloudProductionUrl;
          }

          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Debug Request Logging
          developer.log('[API REQ] ${options.method} ${options.baseUrl}${options.path}', name: 'CareConnect.Network');
          if (options.data != null && options.data is Map) {
            final loggedData = Map<String, dynamic>.from(options.data as Map);
            if (loggedData.containsKey('password')) loggedData['password'] = '******';
            developer.log('[API REQ DATA] $loggedData', name: 'CareConnect.Network');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log('[API RES] ${response.statusCode} from ${response.requestOptions.baseUrl}${response.requestOptions.path}', name: 'CareConnect.Network');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          developer.log('[API ERR] ${error.type} on ${error.requestOptions.baseUrl}${error.requestOptions.path}: ${error.message}', name: 'CareConnect.Network');
          
          // Automatic Failover: If local/custom URL failed with connection error, retry using Production Cloud URL
          final isNetworkError = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout;

          if (isNetworkError && error.requestOptions.baseUrl != ApiConfig.cloudProductionUrl) {
            developer.log('[API AUTO-FAILOVER] Retrying request against Production Cloud URL: ${ApiConfig.cloudProductionUrl}', name: 'CareConnect.Network');
            try {
              final fallbackOptions = error.requestOptions.copyWith(
                baseUrl: ApiConfig.cloudProductionUrl,
              );
              final fallbackResponse = await _dio.fetch(fallbackOptions);
              await _storageService.saveApiBaseUrl(ApiConfig.cloudProductionUrl);
              developer.log('[API AUTO-FAILOVER SUCCESS] Succeeded on cloud backend!', name: 'CareConnect.Network');
              return handler.resolve(fallbackResponse);
            } catch (fallbackError) {
              developer.log('[API AUTO-FAILOVER FAILED] Fallback also failed: $fallbackError', name: 'CareConnect.Network');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  /// Check online server connectivity and latency
  Future<Map<String, dynamic>> checkOnlineHealth([String? testUrl]) async {
    final targetUrl = testUrl ?? (await _storageService.getApiBaseUrl()) ?? ApiConfig.baseUrl;
    final stopwatch = Stopwatch()..start();
    try {
      final tempDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await tempDio.get('${targetUrl.replaceAll(RegExp(r'/+$'), '')}/health');
      stopwatch.stop();
      return {
        'isOnline': response.statusCode == 200,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'serverUrl': targetUrl,
        'status': response.data?['status'] ?? 'online',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'isOnline': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'serverUrl': targetUrl,
        'error': e.toString(),
      };
    }
  }

  // =========================================================================
  // Auth Methods
  // =========================================================================
  Future<Response> login(String email, String password) async {
    return await _dio.post(
      ApiConfig.loginEndpoint,
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register(String email, String password, String fullName, {String role = 'resident'}) async {
    return await _dio.post(
      ApiConfig.registerEndpoint,
      data: {'email': email, 'password': password, 'full_name': fullName, 'role': role},
    );
  }

  Future<Response> getMe() async {
    return await _dio.get(ApiConfig.meEndpoint);
  }

  // =========================================================================
  // Upgraded SOS Alert Methods
  // =========================================================================
  Future<Response> createSosAlert({
    required String category,
    String? message,
    double? latitude,
    double? longitude,
    String priority = 'CRITICAL',
    int? residentId,
  }) async {
    return await _dio.post(
      ApiConfig.sosEndpoint,
      data: {
        'category': category,
        'alert_type': category,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'priority': priority,
        if (residentId != null) 'resident_id': residentId,
      },
    );
  }

  Future<Response> getSosAlerts({String? statusFilter, String? category}) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams['status_filter'] = statusFilter;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    return await _dio.get(
      ApiConfig.sosEndpoint,
      queryParameters: queryParams,
    );
  }

  Future<Response> getSosAlert(int id) async {
    return await _dio.get('${ApiConfig.sosEndpoint}/$id');
  }

  Future<Response> acknowledgeSos(int id) async {
    return await _dio.post('${ApiConfig.sosEndpoint}/$id/acknowledge');
  }

  Future<Response> respondToSos(int id, {String? notes}) async {
    return await _dio.post(
      '${ApiConfig.sosEndpoint}/$id/respond',
      data: {if (notes != null) 'notes': notes},
    );
  }

  Future<Response> resolveSos(int id, {String? notes}) async {
    return await _dio.post(
      '${ApiConfig.sosEndpoint}/$id/resolve',
      data: {if (notes != null) 'notes': notes},
    );
  }

  Future<Response> cancelSos(int id, {String? reason}) async {
    return await _dio.post(
      '${ApiConfig.sosEndpoint}/$id/cancel',
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<Response> getSosAnalytics() async {
    return await _dio.get('${ApiConfig.sosEndpoint}/monitoring');
  }

  // =========================================================================
  // In-App Notification Center Methods
  // =========================================================================
  Future<Response> getNotifications({bool unreadOnly = false, String? channel}) async {
    final queryParams = <String, dynamic>{};
    if (unreadOnly) queryParams['unread_only'] = true;
    if (channel != null) queryParams['channel'] = channel;
    return await _dio.get(
      ApiConfig.notificationsEndpoint,
      queryParameters: queryParams,
    );
  }

  Future<Response> markNotificationRead(int id) async {
    return await _dio.put('${ApiConfig.notificationsEndpoint}/$id/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return await _dio.put('${ApiConfig.notificationsEndpoint}/read-all');
  }

  Future<Response> getNotificationStats() async {
    return await _dio.get('${ApiConfig.notificationsEndpoint}/stats');
  }

  // =========================================================================
  // Incidents Legacy Workflow Methods (Preserved & Enhanced)
  // =========================================================================
  Future<Response> triggerSos(
    String category,
    String location,
    double latitude,
    double longitude, {
    String? description,
  }) async {
    return await _dio.post(
      '/api/incidents/trigger',
      data: {
        'emergency_type': category,
        'incident_type': category,
        'description': description ?? 'Immediate emergency assistance requested',
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<Response> triggerIncident({
    required String incidentType,
    required String description,
    String? location,
  }) async {
    return await _dio.post(
      '/api/incidents/trigger',
      data: {
        'incident_type': incidentType,
        'description': description,
        'location': location ?? 'Current GPS Location',
      },
    );
  }

  Future<Response> getIncidents({String? statusFilter}) async {
    final query = statusFilter != null ? '?status_filter=$statusFilter' : '';
    return await _dio.get('/api/incidents$query');
  }

  Future<Response> updateIncidentStatus(
    int incidentId,
    String status, {
    String? responderName,
    String? responderRole,
  }) async {
    return await _dio.put(
      '/api/incidents/$incidentId/status',
      data: {
        'status': status,
        if (responderName != null) 'responder_name': responderName,
        if (responderRole != null) 'responder_role': responderRole,
      },
    );
  }

  // =========================================================================
  // AI & Entity Methods
  // =========================================================================
  Future<Response> classifyEmergency(String description) async {
    return await _dio.post(
      '/api/ai/classify-emergency',
      data: {'description': description},
    );
  }

  Future<Response> analyzeNotes(String fullName, int age, String medicalNotes) async {
    return await _dio.post(
      '/api/ai/analyze-notes',
      data: {'full_name': fullName, 'age': age, 'medical_notes': medicalNotes},
    );
  }

  Future<Response> chatAI(String query, {Map<String, dynamic>? context}) async {
    return await _dio.post(
      '/api/ai/chat',
      data: {'query': query, 'context': context},
    );
  }

  Future<Response> getResidents() async {
    return await _dio.get('/api/residents');
  }

  Future<Response> getGuardians(int residentId) async {
    return await _dio.get('/api/guardians/resident/$residentId');
  }

  Future<Response> getAnalytics() async {
    return await _dio.get('/api/incidents/analytics');
  }
}
