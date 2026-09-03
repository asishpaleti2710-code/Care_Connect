import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthNotifier({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService(),
        super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _storageService.getToken();
    final userJson = await _storageService.getUser();

    if (token != null && userJson != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(isAuthenticated: true, user: user, isLoading: false);
      } catch (e) {
        await logout();
      }
    } else {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    developer.log('[AUTH] Attempting login for email: $email', name: 'CareConnect.Auth');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.login(email, password);
      final data = response.data;
      final token = data['access_token'];
      final user = UserModel.fromJson(data['user'] ?? data);

      await _storageService.saveToken(token);
      await _storageService.saveUser(jsonEncode(user.toJson()));

      developer.log('[AUTH SUCCESS] User logged in: ${user.fullName} (${user.role}) - ID: ${user.id}', name: 'CareConnect.Auth');
      state = AuthState(isAuthenticated: true, user: user, isLoading: false);
      return true;
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        errorMessage = e.response!.data['detail'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Check your internet connection or switch to Cloud Server.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to reach backend server. Tap the server settings icon to switch to Cloud Server.';
      } else {
        errorMessage = e.message ?? 'Login failed. Please check credentials.';
      }

      developer.log('[AUTH ERROR] Login failed: $errorMessage', name: 'CareConnect.Auth');
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    } catch (e) {
      developer.log('[AUTH EXCEPTION] Unexpected error during login: $e', name: 'CareConnect.Auth');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, {String role = 'resident'}) async {
    developer.log('[AUTH] Attempting registration for email: $email, role: $role, name: $fullName', name: 'CareConnect.Auth');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.register(email, password, fullName, role: role);
      final data = response.data;
      
      // If registration returns access_token directly, auto-login
      if (data['access_token'] != null) {
        final token = data['access_token'];
        final user = UserModel.fromJson(data['user'] ?? data);
        await _storageService.saveToken(token);
        await _storageService.saveUser(jsonEncode(user.toJson()));
        developer.log('[AUTH SUCCESS] Registration and auto-login successful: ${user.fullName}', name: 'CareConnect.Auth');
        state = AuthState(isAuthenticated: true, user: user, isLoading: false);
      } else {
        developer.log('[AUTH SUCCESS] Registration successful, awaiting manual login', name: 'CareConnect.Auth');
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        errorMessage = e.response!.data['detail'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timed out. Check your internet connection or switch to Cloud Server.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to reach backend server. Tap the server settings icon to switch to Cloud Server.';
      } else {
        errorMessage = e.message ?? 'Registration failed.';
      }

      developer.log('[AUTH ERROR] Registration failed: $errorMessage', name: 'CareConnect.Auth');
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    } catch (e) {
      developer.log('[AUTH EXCEPTION] Unexpected error during registration: $e', name: 'CareConnect.Auth');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
