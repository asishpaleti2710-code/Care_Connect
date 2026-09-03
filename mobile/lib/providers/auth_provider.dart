import 'dart:convert';
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.login(email, password);
      final data = response.data;
      final token = data['access_token'];
      final user = UserModel.fromJson(data['user'] ?? data);

      await _storageService.saveToken(token);
      await _storageService.saveUser(jsonEncode(user.toJson()));

      state = AuthState(isAuthenticated: true, user: user, isLoading: false);
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Login failed. Please check credentials.';
      state = state.copyWith(isLoading: false, errorMessage: detail);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, {String role = 'resident'}) async {
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
        state = AuthState(isAuthenticated: true, user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Registration failed.';
      state = state.copyWith(isLoading: false, errorMessage: detail);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
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
