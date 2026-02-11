import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/market.dart';
import '../../utils/finance_rules.dart';
import '../repository/stock_repository.dart';

class FavoritesStore {
  static const _k = 'favorites_v2';

  Future<List<StockSearchItem>> load(Market m) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return [];

    final List list = jsonDecode(raw);
    final items = <StockSearchItem>[];

    for (final e in list) {
      if (e is Map) {
        final mm = e.cast<String, dynamic>();

        final marketName = mm['m']?.toString() ?? 'kr';
        if (marketName != m.name) continue;

        items.add(StockSearchItem(
          code: mm['code']?.toString() ?? '',
          name: mm['name']?.toString() ?? '',
          market: mm['market']?.toString() ?? '',
        ));
      }
    }

    return items;
  }

  Future<bool> isFavorite(Market m, String code) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return false;

    final key = FinanceRules.key(m, code);
    final List list = jsonDecode(raw);
    return list.any((e) => e is Map && (e['key']?.toString() == key));
  }

  Future<void> add(Market m, StockSearchItem item) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    final List list = (raw == null || raw.isEmpty) ? [] : jsonDecode(raw);

    final key = FinanceRules.key(m, item.code);

    // 중복 제거 후 추가
    list.removeWhere((e) => e is Map && (e['key']?.toString() == key));
    list.insert(0, {
      'key': key,
      'm': m.name,
      'code': item.code,
      'name': item.name,
      'market': item.market,
    });

    await sp.setString(_k, jsonEncode(list));
  }

  Future<void> remove(Market m, String code) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return;

    final key = FinanceRules.key(m, code);
    final List list = jsonDecode(raw);
    list.removeWhere((e) => e is Map && (e['key']?.toString() == key));

    await sp.setString(_k, jsonEncode(list));
  }

  Future<void> clear(Market m) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return;

    final List list = jsonDecode(raw);
    list.removeWhere((e) => e is Map && (e['m']?.toString() == m.name));

    await sp.setString(_k, jsonEncode(list));
  }
}
