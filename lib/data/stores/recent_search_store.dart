import 'package:shared_preferences/shared_preferences.dart';
import '../../models/market.dart'; // Market enum 경로에 맞게 수정

class RecentSearchStore {
  static const _max = 5;

  static String _key(Market m) => m == Market.kr ? 'recent_kr' : 'recent_us';

  Future<List<String>> load(Market market) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_key(market)) ?? <String>[];
  }

  Future<void> add(Market market, String text) async {
    final sp = await SharedPreferences.getInstance();
    final key = _key(market);

    final list = sp.getStringList(key) ?? <String>[];
    final v = text.trim();
    if (v.isEmpty) return;

    list.removeWhere((e) => e.toLowerCase() == v.toLowerCase());
    list.insert(0, v);

    if (list.length > _max) list.removeRange(_max, list.length);

    await sp.setStringList(key, list);
  }

  Future<void> clear(Market market) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key(market));
  }
}