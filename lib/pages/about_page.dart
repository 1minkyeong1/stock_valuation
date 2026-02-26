import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'terms_text.dart';
import 'privacy_text.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _info = info);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            // 화면 작은 기기에서도 너무 커지지 않게 제한
            height: mq.size.height * 0.55,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('링크 형식이 올바르지 않습니다.');
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showSnack('링크를 열 수 없습니다.');
  }

  Future<void> _sendEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
      },
    );

    final ok = await launchUrl(uri);
    if (!ok) _showSnack('메일 앱을 열 수 없습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final versionText = (_info == null)
        ? '불러오는 중...'
        : '${_info!.version} (${_info!.buildNumber})';

    // ✅ 앱 정보
    const companyName = 'KMIN';
    const companyDesc = '투기적인 매매가 아닌 원칙 있는 투자, 불확실한 미래 예측보다 확실한 재무 수치에 집중하는 보수적 투자자를 위한 앱입니다.';
    const supportEmail = 'k17mnk@gmail.com';

    // ✅ 스토어 링크 (패키지명 실제 값으로 바꾸세요)
    const androidStoreUrl =
        'https://play.google.com/store/apps/details?id=com.kmin.stock_valuation_app';

    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/branding/company_logo.png',
                  width: 95,
                  height: 37,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, size: 48),
                ),
                const SizedBox(height: 10),
                const Text(
                  companyName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    companyDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                Text('버전: $versionText', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('문의', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('이메일 문의'),
            subtitle: Text(supportEmail),
            onTap: () => _sendEmail(supportEmail, subject: '[앱 문의]'),
          ),
          // ListTile(
          //   leading: const Icon(Icons.chat_outlined),
          //   title: const Text('오픈채팅/메신저'),
          //   subtitle: const Text('빠른 문의'),
          //   onTap: () => _openUrl(kakaoOpenChatUrl),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.home_outlined),
          //   title: const Text('홈페이지'),
          //   subtitle: const Text('공지/FAQ'),
          //   onTap: () => _openUrl(homepageUrl),
          // ),

          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('업데이트', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('스토어에서 업데이트 확인'),
            subtitle: const Text('최신 버전 설치'),
            onTap: () => _openUrl(androidStoreUrl),
          ),

          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('기타', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            onTap: () => _showTextDialog('이용약관', TermsText.content),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            onTap: () => _showTextDialog('개인정보처리방침', PrivacyText.content),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('오픈소스 라이선스'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: '주식적정가계산기',
              applicationVersion: versionText,
            ),
          ),
        ],
      ),
    );
  }
}
