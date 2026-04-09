import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _checking = false;
  static bool _hasUpdate = false;
  static bool _canImmediateUpdate = false;
  static bool _canFlexibleUpdate = false;
  static String? _lastError;

  static bool get hasUpdate => _hasUpdate;
  static bool get canImmediateUpdate => _canImmediateUpdate;
  static bool get canFlexibleUpdate => _canFlexibleUpdate;
  static String? get lastError => _lastError;

  static Future<void> checkForUpdate() async {
    if (_checking) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    _checking = true;
    _lastError = null;

    try {
      final info = await InAppUpdate.checkForUpdate();

      _hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      _canImmediateUpdate = info.immediateUpdateAllowed;
      _canFlexibleUpdate = info.flexibleUpdateAllowed;

      debugPrint(
        '[AppUpdate] availability=${info.updateAvailability}, '
        'immediateAllowed=${info.immediateUpdateAllowed}, '
        'flexibleAllowed=${info.flexibleUpdateAllowed}, '
        'availableVersionCode=${info.availableVersionCode}, '
        'installStatus=${info.installStatus}, '
        'stalenessDays=${info.clientVersionStalenessDays}, '
        'priority=${info.updatePriority}',
      );
    } catch (e, s) {
      _hasUpdate = false;
      _canImmediateUpdate = false;
      _canFlexibleUpdate = false;
      _lastError = e.toString();

      debugPrint('[AppUpdate] checkForUpdate error: $e');
      debugPrint('$s');
    } finally {
      _checking = false;
    }
  }

  static Future<bool> startImmediateUpdate() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;

    try {
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (e, s) {
      _lastError = e.toString();
      debugPrint('[AppUpdate] performImmediateUpdate error: $e');
      debugPrint('$s');
      return false;
    }
  }
}