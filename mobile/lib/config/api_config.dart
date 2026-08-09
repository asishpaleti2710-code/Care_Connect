import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Preset Cloud & Online Base URLs
  static const String cloudProductionUrl = 'https://careconnect-backend.onrender.com';
  static const String cloudCustomDomain = 'https://api.careconnect.app';
  static const String localTunnelUrl = 'http://localhost:8000';

  // Default Platform-Aware Local Network Base URL
  static String get localNetworkUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  // Active Base URL getter with fallback
  static String get baseUrl => localNetworkUrl;

  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';
  static const String healthEndpoint = '/health';
}
