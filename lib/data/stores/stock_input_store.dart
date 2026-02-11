import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StockInputs {
  final double eps;
  final double bps;
  final double dps;
  final double rPct;

  const StockInputs({
    required this.eps,
    required this.bps,
    required this.dps,
    required this.rPct,
  });

  Map<String, dynamic> toJson() => {
    'eps': eps,
    'bps': bps,
    'dps': dps,
    'rPct': rPct,
  };

  static StockInputs fromJson(Map<String, dynamic> m) => StockInputs(
    eps: (m['eps'] as num).toDouble(),
    bps: (m['bps'] as num).toDouble(),
    dps: (m['dps'] as num).toDouble(),
    rPct: (m['rPct'] as num).toDouble(),
  );
}

class StockInputStore {
  static const _key = 'stock_inputs_v1';

  Future<Map<String, dynamic>> _loadAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> _saveAll(Map<String, dynamic> all) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(all));
  }

  Future<StockInputs?> load(String key) async {
    final all = await _loadAll();
    final v = all[key];
    if (v == null) return null;
    return StockInputs.fromJson((v as Map).cast<String, dynamic>());
  }

  Future<void> save(String key, StockInputs inputs) async {
    final all = await _loadAll();
    all[key] = inputs.toJson();
    await _saveAll(all);
  }

  Future<void> remove(String key) async {
    final all = await _loadAll();
    all.remove(key);
    await _saveAll(all);
  }
}
