import 'package:flutter/material.dart';
import 'package:stock_valuation_app/copy/sell_guide_copy.dart';

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
    final copy = SellGuideCopy.build(context, gapPct: gap);

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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
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
                  Expanded(
                    child: Text(
                      copy.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                    tooltip: copy.closeTooltip,
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
                  copy.headerText,
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                copy.checklistTitle,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final item in copy.items) _check(item.title, item.desc),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => setState(() => _showMore = !_showMore),
                icon: Icon(_showMore ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  _showMore ? copy.collapseLabel : copy.expandLabel,
                ),
              ),
              if (_showMore) ...[
                const SizedBox(height: 8),
                Text(
                  copy.summaryTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  copy.summaryBody,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: Colors.black87,
                  ),
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
                child: Text(
                  copy.disclaimer,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}