import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/market.dart';
import '../../utils/finance_rules.dart';
import '../repository/stock_repository.dart';

class RecentStore {
  static const _k = 'recents_v2';

  Future<List<StockSearchItem>> load(Market m) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return [];

    final List list = jsonDecode(raw);
    final items = <StockSearchItem>[];

    for (final e in list) {
      if (e is Map<String, dynamic>) {
        final marketName = e['m']?.toString() ?? 'kr';
        if (marketName != m.name) continue;

        items.add(StockSearchItem(
          code: e['code']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          market: e['market']?.toString() ?? '',
        ));
      }
    }
    return items;
  }

  Future<void> add(Market m, StockSearchItem item) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    final List list = (raw == null || raw.isEmpty) ? [] : jsonDecode(raw);

    final key = FinanceRules.key(m, item.code);

    // 기존 같은 항목 제거 후 맨 앞에 삽입
    list.removeWhere((e) => e is Map && (e['key']?.toString() == key));
    list.insert(0, {
      'key': key,
      'm': m.name,
      'code': item.code,
      'name': item.name,
      'market': item.market,
    });

    // 길이 제한 (예: 30개)
    while (list.length > 30) {
      list.removeLast();
    }

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
