import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AppBackupFileLabels {
  final String shareText;
  final String platformNotSupportedText;

  const AppBackupFileLabels({
    required this.shareText,
    required this.platformNotSupportedText,
  });

  static AppBackupFileLabels defaults({required bool isKo}) {
    if (isKo) {
      return const AppBackupFileLabels(
        shareText: '주식 평가 앱 백업 파일입니다.',
        platformNotSupportedText: '이 플랫폼에서는 백업 파일 저장을 지원하지 않습니다.',
      );
    }

    return const AppBackupFileLabels(
      shareText: 'This is a backup file for the stock valuation app.',
      platformNotSupportedText:
          'Saving backup files is not supported on this platform.',
    );
  }
}

class AppBackupFileService {
  AppBackupFileService();

  static final XTypeGroup _jsonTypeGroup = XTypeGroup(
    label: 'json',
    extensions: ['json'],
    mimeTypes: ['application/json', 'text/json', 'text/plain'],
  );

  Future<String?> saveBackupFile(
    String jsonText, {
    required AppBackupFileLabels labels,
  }) async {
    final fileName = _buildFileName();
    final bytes = utf8.encode(jsonText);

    if (_isDesktop) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [_jsonTypeGroup],
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
        text: labels.shareText,
      );

      return file.path;
    }

    throw Exception(labels.platformNotSupportedText);
  }

  Future<String?> pickBackupFileAndRead() async {
    final file = await openFile(
      acceptedTypeGroups: [_jsonTypeGroup],
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return _decodeUtf8Text(bytes);
  }

  String _decodeUtf8Text(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      bytes = bytes.sublist(3);
    }

    return utf8.decode(bytes, allowMalformed: false);
  }

  String _buildFileName() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    return 'stock_valuation_backup_${y}${m}${d}_${hh}${mm}${ss}.json';
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;
}