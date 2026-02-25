import 'package:flutter/services.dart';

/// 숫자 입력 포맷터
/// - 천단위 콤마
/// - 소수 허용 옵션
/// - 음수 허용 옵션(맨 앞 '-' 1개만)
class MoneyInputFormatter extends TextInputFormatter {
  final bool allowDecimal;
  final int decimalDigits;
  final bool allowNegative;

  MoneyInputFormatter({
    required this.allowDecimal,
    this.decimalDigits = 2,
    this.allowNegative = false,
  });

  static String _withComma(String s) {
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    // 비어있으면 그대로
    if (raw.isEmpty) return newValue;

    // 콤마 제거
    var t = raw.replaceAll(',', '');

    // ✅ 음수 처리 (맨 앞 '-' 1개만 허용)
    bool neg = false;
    if (allowNegative) {
      if (t.startsWith('-')) neg = true;
      t = t.replaceAll('-', '');
    }

    // 숫자/소수점 외 제거
    if (allowDecimal) {
      t = t.replaceAll(RegExp(r'[^0-9.]'), '');

      // 점이 여러개면 첫 점만 남기기
      final firstDot = t.indexOf('.');
      if (firstDot != -1) {
        final before = t.substring(0, firstDot + 1);
        final after = t.substring(firstDot + 1).replaceAll('.', '');
        t = before + after;
      }

      // 소수 자릿수 제한
      final dot = t.indexOf('.');
      if (dot != -1) {
        final parts = t.split('.');
        final intPart = parts[0];
        final decPart = (parts.length > 1) ? parts[1] : '';
        final trimmedDec = decPart.length > decimalDigits
            ? decPart.substring(0, decimalDigits)
            : decPart;
        t = '$intPart.$trimmedDec';
      }
    } else {
      t = t.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // ✅ "-"만 입력 중인 상태 허용
    if (allowNegative && neg && t.isEmpty) {
      return const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    if (t.isEmpty) return const TextEditingValue(text: '');

    // 정수/소수 분리 후 정수부 콤마
    String formatted;
    if (allowDecimal && t.contains('.')) {
      final parts = t.split('.');
      final intPart = parts[0].isEmpty ? '0' : parts[0];
      final decPart = parts.length > 1 ? parts[1] : '';
      formatted = '${_withComma(intPart)}.$decPart';
    } else {
      formatted = _withComma(t);
    }

    if (allowNegative && neg) {
      formatted = '-$formatted';
    }

    // 커서: 끝으로
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}