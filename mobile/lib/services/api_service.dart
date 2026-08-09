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
          // Dynamic online / custom base URL routing
          final customUrl = await _storageService.getApiBaseUrl();
          if (customUrl != null && customUrl.trim().isNotEmpty) {
            options.baseUrl = customUrl.trim();
          }

          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
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

  // Auth Methods
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

  // SOS & Incidents Methods
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

  Future<Response> updateIncidentStatus(int incidentId, String status) async {
    return await _dio.put(
      '/api/incidents/$incidentId/status',
      data: {'status': status},
    );
  }

  // AI Module Methods
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

  // Residents Methods
  Future<Response> getResidents() async {
    return await _dio.get('/api/residents');
  }

  // Guardians Methods
  Future<Response> getGuardians(int residentId) async {
    return await _dio.get('/api/guardians/resident/$residentId');
  }

  // Analytics Methods
  Future<Response> getAnalytics() async {
    return await _dio.get('/api/incidents/analytics');
  }
}
