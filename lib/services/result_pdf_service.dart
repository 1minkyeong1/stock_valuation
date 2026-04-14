import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ResultPdfLabels {
  final String inputSectionTitle;
  final String resultSectionTitle;
  final String ratingSummarySectionTitle;
  final String financialSummarySectionTitle;
  final String noteSectionTitle;

  final String currentPriceLabel;
  final String epsLabel;
  final String bpsLabel;
  final String dpsLabel;
  final String requiredReturnLabel;

  final String fairPriceLabel;
  final String expectedReturnLabel;
  final String valuationStatusLabel;
  final String roeLabel;
  final String dividendYieldLabel;
  final String perLabel;
  final String pbrLabel;

  final String ratingLabel;
  final String financialBasisLabel;
  final String revenueLabel;
  final String opIncomeLabel;
  final String netIncomeLabel;
  final String equityLabel;
  final String liabilitiesLabel;
  final String financialSourceLabel;

  final String calcUnavailablePrefix;
  final String disclaimerText;
  final String shareTextSuffix;
  final String platformNotSupportedText;
  final String fontLoadErrorText;
  final String explanationSectionTitle;

  const ResultPdfLabels({
    required this.inputSectionTitle,
    required this.resultSectionTitle,
    required this.ratingSummarySectionTitle,
    required this.financialSummarySectionTitle,
    required this.noteSectionTitle,
    required this.currentPriceLabel,
    required this.epsLabel,
    required this.bpsLabel,
    required this.dpsLabel,
    required this.requiredReturnLabel,
    required this.fairPriceLabel,
    required this.expectedReturnLabel,
    required this.valuationStatusLabel,
    required this.roeLabel,
    required this.dividendYieldLabel,
    required this.perLabel,
    required this.pbrLabel,
    required this.ratingLabel,
    required this.financialBasisLabel,
    required this.revenueLabel,
    required this.opIncomeLabel,
    required this.netIncomeLabel,
    required this.equityLabel,
    required this.liabilitiesLabel,
    required this.financialSourceLabel,
    required this.calcUnavailablePrefix,
    required this.disclaimerText,
    required this.shareTextSuffix,
    required this.platformNotSupportedText,
    required this.fontLoadErrorText,
    required this.explanationSectionTitle,
  });

  String shareText(String name) => '$name $shareTextSuffix';

}

class ResultPdfData {
  final String name;
  final String? originalName;
  final String code;
  final String marketText;

  final String sourceText;
  final String? metaText;

  final bool includeEvaluation;
  final bool includeFinancials;

  final String currentPriceText;
  final String epsText;
  final String bpsText;
  final String dpsText;
  final String rPctText;

  final String? fairPriceText;
  final String? expectedReturnText;
  final String? gapText;
  final String? roeText;
  final String? dividendYieldText;
  final String? perText;
  final String? pbrText;

  final String? ratingTitle;
  final String? ratingSummary;
  final String? calcError;

  final String? financialPeriodText;
  final String? revenueText;
  final String? opIncomeText;
  final String? netIncomeText;
  final String? equityText;
  final String? liabilitiesText;
  final String? fsSourceText;
  final List<String>? explanationParagraphs;

  final ResultPdfLabels labels;

  const ResultPdfData({
    required this.name,
    this.originalName,
    required this.code,
    required this.marketText,
    required this.sourceText,
    this.metaText,
    this.includeEvaluation = true,
    this.includeFinancials = false,
    required this.currentPriceText,
    required this.epsText,
    required this.bpsText,
    required this.dpsText,
    required this.rPctText,
    this.fairPriceText,
    this.expectedReturnText,
    this.gapText,
    this.roeText,
    this.dividendYieldText,
    this.perText,
    this.pbrText,
    this.ratingTitle,
    this.ratingSummary,
    this.calcError,
    this.financialPeriodText,
    this.revenueText,
    this.opIncomeText,
    this.netIncomeText,
    this.equityText,
    this.liabilitiesText,
    this.fsSourceText,
    this.explanationParagraphs,

    required this.labels,
  });
}

class ResultPdfService {
  static final XTypeGroup _pdfTypeGroup = XTypeGroup(
    label: 'pdf',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
  );

  Future<(pw.Font, pw.Font)> _loadPdfFonts(ResultPdfLabels labels) async {
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf');

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

  Future<Uint8List> buildPdfBytes(ResultPdfData data) async {
    final labels = data.labels;
    final (baseFont, boldFont) = await _loadPdfFonts(labels);

    final doc = pw.Document(
      title: '${data.name} (${data.code})',
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
          if (data.originalName != null && data.originalName!.trim().isNotEmpty)
            ...[
              pw.SizedBox(height: 4),
              pw.Text(
                data.originalName!,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          pw.SizedBox(height: 10),
          if (data.metaText != null && data.metaText!.trim().isNotEmpty) ...[
            ..._metaLines(data.metaText!),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            data.sourceText,
            style: const pw.TextStyle(fontSize: 10),
          ),

          if (data.includeEvaluation) ...[
            pw.SizedBox(height: 10),
            _section(
              labels.inputSectionTitle,
              [
                _kv(labels.currentPriceLabel, data.currentPriceText),
                _kv(labels.epsLabel, data.epsText),
                _kv(labels.bpsLabel, data.bpsText),
                _kv(labels.dpsLabel, data.dpsText),
                _kv(labels.requiredReturnLabel, data.rPctText),
              ],
            ),
            pw.SizedBox(height: 9),
            _section(
              labels.resultSectionTitle,
              [
                _kv(labels.fairPriceLabel, data.fairPriceText ?? '-'),
                _kv(labels.expectedReturnLabel, data.expectedReturnText ?? '-'),
                _kv(labels.valuationStatusLabel, data.gapText ?? '-'),
                _kv(labels.roeLabel, data.roeText ?? '-'),
                _kv(labels.dividendYieldLabel, data.dividendYieldText ?? '-'),
                _kv(labels.perLabel, data.perText ?? '-'),
                _kv(labels.pbrLabel, data.pbrText ?? '-'),
              ],
            ),
          ],

          if (data.ratingTitle != null || data.ratingSummary != null) ...[
            pw.SizedBox(height: 9),
            _section(
              labels.ratingSummarySectionTitle,
              [
                _kv(labels.ratingLabel, data.ratingTitle ?? '-'),
                if (data.ratingSummary != null &&
                    data.ratingSummary!.trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Text(
                      data.ratingSummary!,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],

          if (data.explanationParagraphs != null &&
              data.explanationParagraphs!.isNotEmpty) ...[
            pw.SizedBox(height: 9),
            _section(
              labels.explanationSectionTitle,
              [
                ...data.explanationParagraphs!.map(
                  (p) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      p,
                      style: const pw.TextStyle(fontSize: 10.5, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (data.includeFinancials) ...[
            pw.SizedBox(height: 9),
            _section(
              labels.financialSummarySectionTitle,
              [
                _kv(labels.financialBasisLabel, data.financialPeriodText ?? '-'),
                _kv(labels.revenueLabel, data.revenueText ?? '-'),
                _kv(labels.opIncomeLabel, data.opIncomeText ?? '-'),
                _kv(labels.netIncomeLabel, data.netIncomeText ?? '-'),
                _kv(labels.equityLabel, data.equityText ?? '-'),
                _kv(labels.liabilitiesLabel, data.liabilitiesText ?? '-'),
                _kv(
                  labels.financialSourceLabel,
                  data.fsSourceText ?? '-',
                  valueColor: PdfColors.grey700,
                  boldValue: false,
                ),
              ],
            ),
          ],

          if (data.calcError != null && data.calcError!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 9),
            _section(
              labels.noteSectionTitle,
              [
                pw.Text(
                  '${labels.calcUnavailablePrefix}: ${data.calcError}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 5),
          pw.Text(
            labels.disclaimerText,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<String?> savePdf(ResultPdfData data) async {
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

  String _buildFileName(ResultPdfData data) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final code = _safeFilePart(data.code);

    String prefix;
    if (data.includeEvaluation && data.includeFinancials) {
      prefix = 'valuation_full';
    } else if (data.includeFinancials) {
      prefix = 'financial_statement';
    } else {
      prefix = 'valuation_result';
    }

    return '${prefix}_${code}_${y}${m}${d}_${hh}${mm}.pdf';
  }

  String _safeFilePart(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
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
      padding: const pw.EdgeInsets.all(9),
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
            width: 108,
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
}