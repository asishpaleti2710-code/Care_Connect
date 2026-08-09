import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/sos_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/residents_screen.dart';
import '../screens/responders_screen.dart';
import '../screens/guardians_screen.dart';
import '../screens/maps_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/lock_screen_hub_screen.dart';

class AppRoutes {
  static const String initial = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String sos = '/sos';
  static const String aiAssistant = '/ai-assistant';
  static const String residents = '/residents';
  static const String responders = '/responders';
  static const String guardians = '/guardians';
  static const String maps = '/maps';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String lockscreenHub = '/lockscreen-hub';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        dashboard: (context) => const DashboardScreen(),
        sos: (context) => const SosScreen(),
        aiAssistant: (context) => const AiAssistantScreen(),
        residents: (context) => const ResidentsScreen(),
        responders: (context) => const RespondersScreen(),
        guardians: (context) => const GuardiansScreen(),
        maps: (context) => const MapsScreen(),
        analytics: (context) => const AnalyticsScreen(),
        settings: (context) => const SettingsScreen(),
        lockscreenHub: (context) => const LockScreenHubScreen(),
      };
}
