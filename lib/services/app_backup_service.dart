import 'dart:convert';

import 'package:stock_valuation_app/data/stores/favorites_store.dart';
import 'package:stock_valuation_app/data/stores/recent_store.dart';
import 'package:stock_valuation_app/data/stores/stock_input_store.dart';

enum AppBackupErrorCode {
  invalidFormat,
  wrongApp,
  unsupportedVersion,
}

class AppBackupException implements Exception {
  final AppBackupErrorCode code;

  const AppBackupException(this.code);

  @override
  String toString() => 'AppBackupException($code)';
}

class AppBackupService {
  AppBackupService();

  final FavoritesStore _favoritesStore = FavoritesStore();
  final RecentStore _recentStore = RecentStore();
  final StockInputStore _inputStore = StockInputStore();

  static const String appId = 'stock_valuation_app';
  static const int backupVersion = 1;

  Future<String> exportJson() async {
    final favorites = await _favoritesStore.exportAllRaw();
    final recents = await _recentStore.exportAllRaw();
    final inputs = await _inputStore.exportAllRaw();

    final root = <String, dynamic>{
      'app': appId,
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'favorites': favorites,
      'recents': recents,
      'inputs': inputs,
    };

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  Future<void> importJson(
    String jsonText, {
    bool overwrite = true,
  }) async {
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map) {
      throw const AppBackupException(AppBackupErrorCode.invalidFormat);
    }

    final root = Map<String, dynamic>.from(decoded);

    if (root['app'] != appId) {
      throw const AppBackupException(AppBackupErrorCode.wrongApp);
    }

    final version = root['version'];
    if (version is! int || version != backupVersion) {
      throw const AppBackupException(AppBackupErrorCode.unsupportedVersion);
    }

    final favorites = _readMapList(root['favorites']);
    final recents = _readMapList(root['recents']);
    final inputs = _readStringDynamicMap(root['inputs']);

    if (overwrite) {
      await _favoritesStore.replaceAllRaw(favorites);
      await _recentStore.replaceAllRaw(recents);
      await _inputStore.replaceAllRaw(inputs);
      return;
    }

    final currentFavorites = await _favoritesStore.exportAllRaw();
    final currentRecents = await _recentStore.exportAllRaw();
    final currentInputs = await _inputStore.exportAllRaw();

    await _favoritesStore.replaceAllRaw(
      _mergeListByKey(currentFavorites, favorites),
    );
    await _recentStore.replaceAllRaw(
      _mergeListByKey(currentRecents, recents),
    );
    await _inputStore.replaceAllRaw(
      _mergeMap(currentInputs, inputs),
    );
  }

  List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _readStringDynamicMap(dynamic value) {
    if (value is! Map) return {};
    return Map<String, dynamic>.from(value);
  }

  List<Map<String, dynamic>> _mergeListByKey(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final row in [...newList, ...oldList]) {
      final key = (row['key'] ?? '').toString().trim();
      if (key.isEmpty) continue;
      if (seen.contains(key)) continue;

      seen.add(key);
      out.add(Map<String, dynamic>.from(row));
    }

    return out;
  }

  Map<String, dynamic> _mergeMap(
    Map<String, dynamic> oldMap,
    Map<String, dynamic> newMap,
  ) {
    return <String, dynamic>{
      ...oldMap,
      ...newMap,
    };
  }
}