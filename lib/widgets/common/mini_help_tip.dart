// 주식보는 설명 툴팁

import 'package:flutter/material.dart';

class MiniHelpTip extends StatelessWidget {
  final String message;
  final Color? color;

  const MiniHelpTip({
    super.key,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;

    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.35,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 12,
        height: 12,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withAlpha(14),
          shape: BoxShape.circle,
          border: Border.all(color: c.withAlpha(55), width: 0.8),
        ),
        child: Icon(
          Icons.question_mark_rounded,
          size: 8,
          color: c.withAlpha(210),
        ),
      ),
    );
  }
}