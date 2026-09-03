import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/lock_screen_service.dart';

class LockScreenSettings {
  final bool isLockScreenEnabled;
  final bool showNotificationWidget;
  final bool showMedicalIdOnLockScreen;
  final bool autoWakeScreenOnSos;
  final bool shakeToSosEnabled;
  final Map<String, dynamic>? activeIncident;

  const LockScreenSettings({
    this.isLockScreenEnabled = true,
    this.showNotificationWidget = true,
    this.showMedicalIdOnLockScreen = true,
    this.autoWakeScreenOnSos = true,
    this.shakeToSosEnabled = true,
    this.activeIncident,
  });

  LockScreenSettings copyWith({
    bool? isLockScreenEnabled,
    bool? showNotificationWidget,
    bool? showMedicalIdOnLockScreen,
    bool? autoWakeScreenOnSos,
    bool? shakeToSosEnabled,
    Map<String, dynamic>? activeIncident,
    bool clearIncident = false,
  }) {
    return LockScreenSettings(
      isLockScreenEnabled: isLockScreenEnabled ?? this.isLockScreenEnabled,
      showNotificationWidget: showNotificationWidget ?? this.showNotificationWidget,
      showMedicalIdOnLockScreen: showMedicalIdOnLockScreen ?? this.showMedicalIdOnLockScreen,
      autoWakeScreenOnSos: autoWakeScreenOnSos ?? this.autoWakeScreenOnSos,
      shakeToSosEnabled: shakeToSosEnabled ?? this.shakeToSosEnabled,
      activeIncident: clearIncident ? null : (activeIncident ?? this.activeIncident),
    );
  }
}

class LockScreenNotifier extends StateNotifier<LockScreenSettings> {
  final LockScreenService _lockScreenService;

  LockScreenNotifier({
    LockScreenService? lockScreenService,
  })  : _lockScreenService = lockScreenService ?? LockScreenService(),
        super(const LockScreenSettings()) {
    _initializeLockScreen();
  }

  Future<void> _initializeLockScreen() async {
    try {
      await _lockScreenService.setLockScreenMode(state.isLockScreenEnabled);
      if (state.showNotificationWidget) {
        await _lockScreenService.showLockScreenNotification(
          title: '🚨 CareConnect Emergency Hub',
          body: 'Direct Lock Screen SOS & Medical ID available.',
        );
      }
    } catch (_) {}
  }

  Future<void> toggleLockScreenEnabled(bool value) async {
    state = state.copyWith(isLockScreenEnabled: value);
    await _lockScreenService.setLockScreenMode(value);
    if (value && state.showNotificationWidget) {
      await _lockScreenService.showLockScreenNotification();
    } else if (!value) {
      await _lockScreenService.dismissLockScreenNotification();
    }
  }

  Future<void> toggleLockScreen(bool value) => toggleLockScreenEnabled(value);

  Future<void> toggleNotificationWidget(bool value) async {
    state = state.copyWith(showNotificationWidget: value);
    if (value && state.isLockScreenEnabled) {
      await _lockScreenService.showLockScreenNotification();
    } else {
      await _lockScreenService.dismissLockScreenNotification();
    }
  }

  void toggleMedicalId(bool value) {
    state = state.copyWith(showMedicalIdOnLockScreen: value);
  }

  void toggleAutoWake(bool value) {
    state = state.copyWith(autoWakeScreenOnSos: value);
  }

  void toggleShakeToSos(bool value) {
    state = state.copyWith(shakeToSosEnabled: value);
  }

  Future<void> setActiveIncident(Map<String, dynamic> incident) async {
    state = state.copyWith(activeIncident: incident);
    if (state.autoWakeScreenOnSos) {
      await _lockScreenService.turnScreenOn();
    }
    await _lockScreenService.showLockScreenNotification(
      title: '🚨 ACTIVE SOS DISPATCHED: ${incident['incident_type'] ?? 'EMERGENCY'}',
      body: 'Status: ${incident['status'] ?? 'In Progress'} • Tap to view on lock screen',
      activeSos: true,
    );
  }

  Future<void> clearActiveIncident() async {
    state = state.copyWith(clearIncident: true);
    if (state.showNotificationWidget) {
      await _lockScreenService.showLockScreenNotification(
        title: '🚨 CareConnect Emergency Hub',
        body: 'Direct Lock Screen SOS & Medical ID available.',
        activeSos: false,
      );
    } else {
      await _lockScreenService.dismissLockScreenNotification();
    }
  }
}

final lockScreenProvider = StateNotifierProvider<LockScreenNotifier, LockScreenSettings>((ref) {
  return LockScreenNotifier();
});
