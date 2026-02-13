import 'package:flutter/material.dart';

enum RatingLevel { strongBuy, buy, neutral, caution, avoid }

class ValuationRating {
  final RatingLevel level;

  /// 예: "강력매수", "매수", "중립", "주의", "피하기"
  final String title;

  /// 한 줄 요약
  final String summary;

  /// 체크리스트(왜 그런 판단인지)
  final List<String> bullets;

  // ✅ 추가: UI 컬러 세트
  final Color? bg;
  final Color? border;
  final Color? accent;

  const ValuationRating({
    required this.level,
    required this.title,
    required this.summary,
    required this.bullets,

    // ✅ 추가
    required this.bg,
    required this.border,
    required this.accent,
  });
}
