class ApiConfig {
  // Production Railway Backend URL (Online 24/7 accessible globally on any Wi-Fi or Mobile Data)
  static const String cloudProductionUrl =
      'https://careconnect-production-bab1.up.railway.app';

  // Active Production Base URL
  static String get baseUrl => cloudProductionUrl;

  // Candidate URLs for connectivity checks
  static const List<String> serverCandidates = [
    cloudProductionUrl,
  ];

  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';
  static const String healthEndpoint = '/health';
  static const String sosEndpoint = '/api/sos';
  static const String notificationsEndpoint = '/api/notifications';
}
