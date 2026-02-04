import 'package:intl/intl.dart';

/// ---------- KR (원화) ----------

final _wonIntFormatter = NumberFormat('#,###', 'ko_KR');

/// 원화 (정수, 원 단위)
String fmtWon(num? value) {
  if (value == null) return '-';
  return '${_wonIntFormatter.format(value.round())}원';
}

/// 원화 (소수 허용: EPS/BPS/DPS용)
String fmtWonDecimal(num? value, {int fractionDigits = 2}) {
  if (value == null) return '-';

  final pattern = '#,##0${fractionDigits > 0 ? '.${'0' * fractionDigits}' : ''}';
  return NumberFormat(pattern, 'ko_KR').format(value);
}

/// ---------- US (달러) ----------

final _usdIntFormatter = NumberFormat('#,##0', 'en_US');

/// 달러 (정수)
String fmtUsd(num? value) {
  if (value == null) return '-';
  return '\$${_usdIntFormatter.format(value.round())}';
}

/// 달러 (소수 2자리 기본)
String fmtUsdDecimal(num? value, {int fractionDigits = 2}) {
  if (value == null) return '-';

  final pattern = '#,##0.${'0' * fractionDigits}';
  return '\$${NumberFormat(pattern, 'en_US').format(value)}';
}
