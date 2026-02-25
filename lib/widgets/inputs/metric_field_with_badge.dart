// EPS BPS DPS 배지 포함 위젯

import 'package:flutter/material.dart';

import 'package:stock_valuation_app/utils/finance_rules.dart';
import 'package:stock_valuation_app/utils/money_input_formatter.dart';

class MetricFieldWithBadge extends StatelessWidget {
  final bool isUS;
  final String label; // EPS/BPS/DPS
  final TextEditingController controller;
  final void Function(String) onChanged;

  const MetricFieldWithBadge({
    super.key,
    required this.isUS,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rawText = controller.text.trim().replaceAll(',', '');
    final isEditingMinusOnly = (rawText == '-');
    final val = (!isEditingMinusOnly) ? (double.tryParse(rawText) ?? 0) : 0.0;

    final up = label.trim().toUpperCase();
    final isEps = up == "EPS";
    final isBps = up == "BPS";
    final isDps = up == "DPS";

    // EPS/BPS만 음수 허용
    final allowNegative = isEps || isBps;

    // 배지 규칙
    final showLoss = isEps && !isEditingMinusOnly && FinanceRules.isLossEps(val);
    final showMissing = !isDps && !isEditingMinusOnly && FinanceRules.isMissing(val);
    final showDpsZero = isDps && (val == 0);

    void toggleSign() {
      final t = controller.text.trim();
      if (t.isEmpty) {
        controller.text = '-';
      } else if (t == '-') {
        controller.text = '';
      } else if (t.startsWith('-')) {
        controller.text = t.substring(1);
      } else {
        controller.text = '-$t';
      }
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      onChanged(controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (showLoss)
              _lossBadge()
            else if (showMissing)
              _autoMissingBadge()
            else if (showDpsZero)
              _dpsZeroBadge(),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            isUS
                ? MoneyInputFormatter(
                    allowDecimal: true,
                    decimalDigits: 2,
                    allowNegative: allowNegative,
                  )
                : MoneyInputFormatter(
                    allowDecimal: false,
                    allowNegative: allowNegative,
                  ),
          ],
          decoration: InputDecoration(
            hintText: "직접 입력 가능",
            border: const OutlineInputBorder(),
            suffixIcon: allowNegative
                ? IconButton(
                    tooltip: '부호 전환(±)',
                    onPressed: toggleSign,
                    icon: const Text('±', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _autoMissingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25),
        border: Border.all(color: Colors.orange.withAlpha(120)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "자동값 없음",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange),
      ),
    );
  }

  Widget _lossBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        border: Border.all(color: Colors.red.withAlpha(120)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "적자(EPS<0)",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
      ),
    );
  }

  Widget _dpsZeroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.withAlpha(80)),
      ),
      child: const Text(
        "무배당/데이터없음",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue),
      ),
    );
  }
}