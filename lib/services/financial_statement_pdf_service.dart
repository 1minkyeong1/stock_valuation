import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class FinancialStatementPdfLabels {
  final String documentTitleSuffix;
  final String summarySectionTitle;
  final String buffettAssistSectionTitle;
  final String trendSectionTitle;
  final String stabilitySectionTitle;

  final String periodLabel;
  final String revenueLabel;
  final String opIncomeLabel;
  final String netIncomeLabel;
  final String equityLabel;
  final String liabilitiesLabel;
  final String financialSourceLabel;

  final String avg3yEpsLabel;
  final String avg5yRoeLabel;

  final String yearlyEpsLabel;
  final String yearlyRoeLabel;

  final String lossYearsLabel;
  final String debtRatioLabel;
  final String recentDividendLabel;

  final String disclaimerText;
  final String shareTextSuffix;
  final String platformNotSupportedText;
  final String fontLoadErrorText;

  const FinancialStatementPdfLabels({
    required this.documentTitleSuffix,
    required this.summarySectionTitle,
    required this.buffettAssistSectionTitle,
    required this.trendSectionTitle,
    required this.stabilitySectionTitle,
    required this.periodLabel,
    required this.revenueLabel,
    required this.opIncomeLabel,
    required this.netIncomeLabel,
    required this.equityLabel,
    required this.liabilitiesLabel,
    required this.financialSourceLabel,
    required this.avg3yEpsLabel,
    required this.avg5yRoeLabel,
    required this.yearlyEpsLabel,
    required this.yearlyRoeLabel,
    required this.lossYearsLabel,
    required this.debtRatioLabel,
    required this.recentDividendLabel,
    required this.disclaimerText,
    required this.shareTextSuffix,
    required this.platformNotSupportedText,
    required this.fontLoadErrorText,
  });

  String shareText(String name) => '$name $shareTextSuffix';

}

class FinancialStatementPdfData {
  final String name;
  final String? originalName;
  final String code;
  final String marketText;

  final String sourceText;
  final String? metaText;

  final String periodText;
  final String revenueText;
  final String opIncomeText;
  final String netIncomeText;
  final String equityText;
  final String liabilitiesText;
  final String? fsSourceText;

  final String epsAvg3yText;
  final String roeAvg5yText;

  final List<String> epsHistoryLines;
  final List<String> roeHistoryLines;

  final String lossYearsText;
  final String debtRatioText;
  final String hasDividendText;

  final FinancialStatementPdfLabels labels;

  const FinancialStatementPdfData({
    required this.name,
    this.originalName,
    required this.code,
    required this.marketText,
    required this.sourceText,
    this.metaText,
    required this.periodText,
    required this.revenueText,
    required this.opIncomeText,
    required this.netIncomeText,
    required this.equityText,
    required this.liabilitiesText,
    this.fsSourceText,
    required this.epsAvg3yText,
    required this.roeAvg5yText,
    required this.epsHistoryLines,
    required this.roeHistoryLines,
    required this.lossYearsText,
    required this.debtRatioText,
    required this.hasDividendText,
    required this.labels,
  });
}

class FinancialStatementPdfService {
  static final XTypeGroup _pdfTypeGroup = XTypeGroup(
    label: 'pdf',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
  );

  Future<(pw.Font, pw.Font)> _loadPdfFonts(
    FinancialStatementPdfLabels labels,
  ) async {
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
      final boldData =
          await rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf');

      if (regularData.lengthInBytes == 0) {
        throw Exception(labels.fontLoadErrorText);
      }
      if (boldData.lengthInBytes == 0) {
        throw Exception(labels.fontLoadErrorText);
      }

      final regularFont = pw.Font.ttf(regularData);
      final boldFont = pw.Font.ttf(boldData);

      return (regularFont, boldFont);
    } catch (_) {
      throw Exception(labels.fontLoadErrorText);
    }
  }

  Future<Uint8List> buildPdfBytes(FinancialStatementPdfData data) async {
    final labels = data.labels;
    final (baseFont, boldFont) = await _loadPdfFonts(labels);

    final doc = pw.Document(
      title: '${data.name} (${data.code}) ${labels.documentTitleSuffix}',
      author: 'Stock Valuation App',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: baseFont,
          boldItalic: boldFont,
        ),
        build: (context) => [
          pw.Text(
            '${data.name} (${data.code}) · ${data.marketText}',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (data.originalName != null && data.originalName!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              data.originalName!,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
          pw.SizedBox(height: 10),
          if (data.metaText != null && data.metaText!.trim().isNotEmpty) ...[
            ..._metaLines(data.metaText!),
            pw.SizedBox(height: 7),
          ],
          pw.Text(
            data.sourceText,
            style: const pw.TextStyle(fontSize: 10),
          ),

          pw.SizedBox(height: 14),
          _section(
            labels.summarySectionTitle,
            [
              _kv(labels.periodLabel, data.periodText),
              _kv(labels.revenueLabel, data.revenueText),
              _kv(labels.opIncomeLabel, data.opIncomeText),
              _kv(labels.netIncomeLabel, data.netIncomeText),
              _kv(labels.equityLabel, data.equityText),
              _kv(labels.liabilitiesLabel, data.liabilitiesText),
              _kv(
                labels.financialSourceLabel,
                data.fsSourceText ?? '-',
                valueColor: PdfColors.grey700,
                boldValue: false,
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          _section(
            labels.buffettAssistSectionTitle,
            [
              _kv(labels.avg3yEpsLabel, data.epsAvg3yText),
              _kv(labels.avg5yRoeLabel, data.roeAvg5yText),
            ],
          ),

          pw.SizedBox(height: 12),
          _section(
            labels.trendSectionTitle,
            [
              pw.Text(
                labels.yearlyEpsLabel,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _historyWrapRow(data.epsHistoryLines),

              pw.SizedBox(height: 12),
              pw.Text(
                labels.yearlyRoeLabel,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _historyWrapRow(data.roeHistoryLines),
            ],
          ),

          pw.SizedBox(height: 12),
          _section(
            labels.stabilitySectionTitle,
            [
              _kv(labels.lossYearsLabel, data.lossYearsText),
              _kv(labels.debtRatioLabel, data.debtRatioText),
              _kv(labels.recentDividendLabel, data.hasDividendText),
            ],
          ),

          pw.SizedBox(height: 14),
          pw.Text(
            labels.disclaimerText,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<String?> savePdf(FinancialStatementPdfData data) async {
    final labels = data.labels;
    final bytes = await buildPdfBytes(data);
    final fileName = _buildFileName(data);

    if (_isDesktop) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [_pdfTypeGroup],
      );

      if (location == null || location.path.isEmpty) {
        return null;
      }

      final file = File(location.path);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    if (_isMobile) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: labels.shareText(data.name),
      );

      return file.path;
    }

    throw Exception(labels.platformNotSupportedText);
  }

  String _buildFileName(FinancialStatementPdfData data) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final code = data.code.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');

    return 'financial_statement_${code}_${y}${m}${d}_${hh}${mm}.pdf';
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  List<pw.Widget> _metaLines(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final out = <pw.Widget>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      out.add(
        pw.Text(
          line,
          style: const pw.TextStyle(fontSize: 10),
        ),
      );

      if (i != lines.length - 1) {
        final isIndustryLine =
            line.startsWith('업종:') || line.startsWith('Industry:');

        out.add(
          pw.SizedBox(height: isIndustryLine ? 6 : 2),
        );
      }
    }
    return out;
  }

  pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _kv(
    String label,
    String value, {
    PdfColor valueColor = PdfColors.black,
    bool boldValue = true,
  }) {
    final lines = value.split('\n');
    final mainValue = lines.isNotEmpty ? lines.first.trim() : value.trim();
    final subValue = lines.length > 1
        ? lines.sublist(1).join(' ').trim()
        : null;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: (subValue == null || subValue.isEmpty)
                ? pw.Text(
                    mainValue,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: valueColor,
                      fontWeight:
                          boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  )
                : pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          mainValue,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: valueColor,
                            fontWeight: boldValue
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Flexible(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 14),
                          child: pw.Align(
                            alignment: pw.Alignment.topRight,
                            child: pw.Text(
                              subValue,
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColors.grey500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  pw.Widget _historyWrapRow(List<String> lines) {
    if (lines.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          '-',
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final visible = lines.take(5).toList();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          pw.Expanded(
            child: _historyCard(visible[i]),
          ),
          if (i != visible.length - 1) pw.SizedBox(width: 10),
        ],
      ],
    );
  }

  pw.Widget _historyCard(String line) {
    final parts = line.split('\n');
    final year = parts.isNotEmpty ? parts.first : '';
    final value = parts.length >= 2 ? parts.sublist(1).join('\n') : '';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4),
            child: pw.Text(
              year,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4),
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}