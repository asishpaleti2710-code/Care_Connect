class ApiConfig {
  // Production Railway Backend URL
  static const String cloudProductionUrl =
      'https://careconnect-production-bab1.up.railway.app';
  static const String cloudCustomDomain = 'https://api.careconnect.app';

  // Active Base URL getter
 static String get baseUrl => 'http://192.168.55.105:8000';

  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';
  static const String healthEndpoint = '/health';
  static const String sosEndpoint = '/api/sos';
  static const String notificationsEndpoint = '/api/notifications';
}
