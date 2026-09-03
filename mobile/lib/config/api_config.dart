class ApiConfig {
  // Production Railway Backend URL (Online 24/7 accessible from anywhere on mobile)
  static const String cloudProductionUrl =
      'https://careconnect-production-bab1.up.railway.app';
  static const String cloudCustomDomain = 'https://api.careconnect.app';

  // Local Wi-Fi Network URL (for testing against local dev machine on same Wi-Fi)
  static const String localLanUrl = 'http://10.222.97.248:8000';

  // Android Emulator local loopback URL
  static const String emulatorUrl = 'http://10.0.2.2:8000';

  // Active Default Base URL - Always defaults to production cloud URL for real devices
  static String get baseUrl => cloudProductionUrl;

  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';
  static const String healthEndpoint = '/health';
  static const String sosEndpoint = '/api/sos';
  static const String notificationsEndpoint = '/api/notifications';
}
