import 'package:flutter/material.dart';

class SellGuideItem {
  final String title;
  final String desc;

  const SellGuideItem({
    required this.title,
    required this.desc,
  });
}

class SellGuideCopyData {
  final String title;
  final String closeTooltip;
  final String headerText;
  final String checklistTitle;
  final List<SellGuideItem> items;
  final String expandLabel;
  final String collapseLabel;
  final String summaryTitle;
  final String summaryBody;
  final String disclaimer;

  const SellGuideCopyData({
    required this.title,
    required this.closeTooltip,
    required this.headerText,
    required this.checklistTitle,
    required this.items,
    required this.expandLabel,
    required this.collapseLabel,
    required this.summaryTitle,
    required this.summaryBody,
    required this.disclaimer,
  });
}

class SellGuideCopy {
  static bool isKo(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ko';
  }

  static SellGuideCopyData build(
    BuildContext context, {
    required double gapPct,
  }) {
    final ko = isKo(context);
    final over = gapPct >= 130;

    if (ko) {
      return SellGuideCopyData(
        title: '잠깐! 팔기 전에 점검(참고)',
        closeTooltip: '닫기',
        headerText:
            '현재/적정: ${gapPct.toStringAsFixed(1)}%\n'
            '${over ? "참고: 130% 이상이면 ‘안전마진 축소’ 관점에서 리밸런싱을 고민할 수 있어요." : "가격보다 ‘사업 가정’(해자/경영/펀더멘털)이 변했는지부터 확인해요."}',
        checklistTitle: '체크리스트',
        items: const [
          SellGuideItem(
            title: '가격 과열(참고)',
            desc: '현재 주가가 적정 주가 대비 충분히 높아져 안전마진이 줄었나요? (예: 130% 이상)',
          ),
          SellGuideItem(
            title: '해자 약화',
            desc: '브랜드/원가우위/네트워크효과 등 경쟁우위가 약해졌나요?',
          ),
          SellGuideItem(
            title: '경영·자본배분 품질',
            desc: '무리한 M&A, 과도한 희석, 주주친화 약화 같은 신호가 있나요?',
          ),
          SellGuideItem(
            title: '기회비용',
            desc: '같은 리스크 대비 더 매력적인 대안(기대수익/안정성)이 있나요?',
          ),
          SellGuideItem(
            title: '산업·펀더멘털 변화',
            desc: '산업 구조 변화로 미래 수익 전망이 악화되었나요?',
          ),
        ],
        expandLabel: '자세히 보기',
        collapseLabel: '설명 접기',
        summaryTitle: '설명(요약)',
        summaryBody:
            '가치투자에서는 주가가 올랐다는 이유만으로 기계적으로 팔기보다, '
            '‘가격(Price)’보다 ‘가치(Value)’와 ‘사업의 질’을 중심으로 판단합니다.\n\n'
            '적정 주가는 참고 기준점일 뿐이며, 기업의 경쟁우위(해자)와 경영 품질, '
            '산업 구조가 유지되는지 점검한 뒤에 보유/리밸런싱 결정을 내리는 방식이 더 일관적입니다.',
        disclaimer:
            '※ 본 가이드는 교육/참고용이며 투자 결과에 대한 책임은 사용자에게 있습니다.',
      );
    }

    return SellGuideCopyData(
      title: 'Pause and review before selling',
      closeTooltip: 'Close',
      headerText:
          'Current / Fair: ${gapPct.toStringAsFixed(1)}%\n'
          '${over ? "Note: At 130% or higher, you may consider rebalancing from a reduced margin-of-safety perspective." : "Before looking at price, first check whether the business assumptions (moat / management / fundamentals) have changed."}',
      checklistTitle: 'Checklist',
      items: const [
        SellGuideItem(
          title: 'Price overheating',
          desc: 'Has the stock risen far enough above fair value that the margin of safety has narrowed? (e.g. 130% or more)',
        ),
        SellGuideItem(
          title: 'Moat weakening',
          desc: 'Has the competitive advantage weakened, such as brand, cost advantage, or network effects?',
        ),
        SellGuideItem(
          title: 'Management / capital allocation quality',
          desc: 'Are there warning signs such as reckless M&A, excessive dilution, or weaker shareholder friendliness?',
        ),
        SellGuideItem(
          title: 'Opportunity cost',
          desc: 'Is there a more attractive alternative with similar risk in terms of expected return or stability?',
        ),
        SellGuideItem(
          title: 'Industry / fundamentals change',
          desc: 'Has the industry structure changed in a way that weakens future earnings prospects?',
        ),
      ],
      expandLabel: 'Read more',
      collapseLabel: 'Collapse',
      summaryTitle: 'Summary',
      summaryBody:
          'In value investing, it is usually more consistent to decide based on '
          'value and business quality rather than selling mechanically just because the stock price has risen.\n\n'
          'Fair value is only a reference point. A more disciplined approach is to check whether the company’s moat, management quality, and industry structure remain intact before deciding whether to hold or rebalance.',
      disclaimer:
          '※ This guide is for educational/reference purposes only. Investment results remain the user’s responsibility.',
    );
  }
}