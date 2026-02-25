import 'package:flutter/material.dart';

class SellGuideSheet extends StatefulWidget {
  final double gapPct; // 현재/적정 * 100
  final VoidCallback onClose;

  const SellGuideSheet({
    super.key,
    required this.gapPct,
    required this.onClose,
  });

  @override
  State<SellGuideSheet> createState() => _SellGuideSheetState();
}

class _SellGuideSheetState extends State<SellGuideSheet> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    final gap = widget.gapPct;
    final over = gap >= 130;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "잠깐! 팔기 전에 점검(참고)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    tooltip: "닫기",
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (over ? Colors.orange : Colors.blueGrey).withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (over ? Colors.orange : Colors.blueGrey).withAlpha(50),
                  ),
                ),
                child: Text(
                  "현재/적정: ${gap.toStringAsFixed(1)}%\n"
                  "${over ? "참고: 130% 이상이면 ‘안전마진 축소’ 관점에서 리밸런싱을 고민할 수 있어요." : "가격보다 ‘사업 가정’(해자/경영/펀더멘털)이 변했는지부터 확인해요."}",
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              const Text("체크리스트", style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _check("가격 과열(참고)", "현재 주가가 적정 주가 대비 충분히 높아져 안전마진이 줄었나요? (예: 130% 이상)"),
              _check("해자 약화", "브랜드/원가우위/네트워크효과 등 경쟁우위가 약해졌나요?"),
              _check("경영·자본배분 품질", "무리한 M&A, 과도한 희석, 주주친화 약화 같은 신호가 있나요?"),
              _check("기회비용", "같은 리스크 대비 더 매력적인 대안(기대수익/안정성)이 있나요?"),
              _check("산업·펀더멘털 변화", "산업 구조 변화로 미래 수익 전망이 악화되었나요?"),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => setState(() => _showMore = !_showMore),
                icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
                label: Text(_showMore ? "설명 접기" : "자세히 보기"),
              ),
              if (_showMore) ...[
                const SizedBox(height: 8),
                const Text("설명(요약)", style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  "가치투자에서는 주가가 올랐다는 이유만으로 기계적으로 팔기보다, "
                  "‘가격(Price)’보다 ‘가치(Value)’와 ‘사업의 질’을 중심으로 판단합니다.\n\n"
                  "적정 주가는 참고 기준점일 뿐이며, 기업의 경쟁우위(해자)와 경영 품질, "
                  "산업 구조가 유지되는지 점검한 뒤에 보유/리밸런싱 결정을 내리는 방식이 더 일관적입니다.",
                  style: TextStyle(fontSize: 12, height: 1.55, color: Colors.black87),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(30)),
                ),
                child: const Text(
                  "※ 본 가이드는 교육/참고용이며 투자 결과에 대한 책임은 사용자에게 있습니다.",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _check(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withAlpha(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}