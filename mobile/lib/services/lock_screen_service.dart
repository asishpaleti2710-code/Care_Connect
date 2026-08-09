import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LockScreenService {
  static const MethodChannel _channel = MethodChannel('com.careconnect.app/lockscreen');

  /// Configures native Android flags (setShowWhenLocked & setTurnScreenOn)
  Future<bool> setLockScreenMode(bool enabled) async {
    if (kIsWeb) return true;
    try {
      final result = await _channel.invokeMethod<bool>('setLockScreenMode', {'enabled': enabled});
      return result ?? true;
    } on MissingPluginException {
      debugPrint('[LockScreenService] Plugin not available on this platform.');
      return false;
    } catch (e) {
      debugPrint('[LockScreenService] Error setting lock screen mode: $e');
      return false;
    }
  }

  /// Wakes the device screen during emergency trigger
  Future<bool> turnScreenOn() async {
    if (kIsWeb) return true;
    try {
      final result = await _channel.invokeMethod<bool>('turnScreenOn');
      return result ?? true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LockScreenService] Error turning screen on: $e');
      return false;
    }
  }

  /// Posts a sticky public notification on the lock screen with emergency shortcuts
  Future<bool> showLockScreenNotification({
    String title = '🚨 CareConnect Emergency Hub',
    String body = 'Quick SOS Dispatch & Medical ID available on Lock Screen.',
    bool activeSos = false,
  }) async {
    if (kIsWeb) return true;
    try {
      final result = await _channel.invokeMethod<bool>('showLockScreenNotification', {
        'title': title,
        'body': body,
        'activeSos': activeSos,
      });
      return result ?? true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LockScreenService] Error showing lock screen notification: $e');
      return false;
    }
  }

  /// Dismisses the persistent lock screen emergency notification
  Future<bool> dismissLockScreenNotification() async {
    if (kIsWeb) return true;
    try {
      final result = await _channel.invokeMethod<bool>('dismissLockScreenNotification');
      return result ?? true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LockScreenService] Error dismissing lock screen notification: $e');
      return false;
    }
  }

  /// Checks if keyguard / lock screen is currently locked
  Future<bool> isScreenLocked() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isScreenLocked');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[LockScreenService] Error checking lock screen status: $e');
      return false;
    }
  }
}
