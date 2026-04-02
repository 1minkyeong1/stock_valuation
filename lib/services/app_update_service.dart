import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _checking = false;
  static bool _hasUpdate = false;

  static bool get hasUpdate => _hasUpdate;

  static Future<void> checkForUpdate() async {
    if (_checking) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    _checking = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      _hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (_) {
      _hasUpdate = false;
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
    } catch (_) {
      return false;
    }
  }
}