import '../models/market.dart';

class FinanceRules {
  // 0 = 미제공/계산불가(자동값 없음)
  static bool isMissing(num v) => v == 0;

  // EPS 음수 = 적자(데이터 존재)
  static bool isLossEps(num eps) => eps < 0;

  // 즐겨찾기/최근검색 등 저장 키 충돌 방지
  static String key(Market m, String codeOrSymbol) => '${m.name}:$codeOrSymbol';

  // 표시용 "연말 기준일"
  static String basDtFromYear(int year) => '${year}1231';
}
