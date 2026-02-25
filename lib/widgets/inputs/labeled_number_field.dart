// 기본 숫자 입력 위젯

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabeledNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool filled;
  final Color? fillColor;

  const LabeledNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.inputFormatters,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.suffixIcon,
    this.filled = true,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText ?? "직접 입력 가능",
            border: const OutlineInputBorder(),
            filled: filled,
            fillColor: fillColor ?? Colors.white.withAlpha(200),
            suffixIcon: suffixIcon,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}