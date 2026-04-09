import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'terms_text.dart';
import 'privacy_text.dart';
import '../services/app_update_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showTextDialog(
    String title,
    String content, {
    String? url,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final t = AppLocalizations.of(ctx)!;

        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
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
            if (url != null)
              TextButton(
                onPressed: () => _openUrl(url),
                child: Text(t.privacyOpenWeb),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showSnack(t.invalidLink);
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      _showSnack(t.cannotOpenLink);
    }
  }

  Future<void> _sendEmail(String email, {String? subject}) async {
    final t = AppLocalizations.of(context)!;

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
      },
    );

    final ok = await launchUrl(uri);
    if (!ok) {
      _showSnack(t.cannotOpenMailApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final versionText = (_info == null)
        ? t.loading
        : '${_info!.version} (${_info!.buildNumber})';

    const companyName = 'KMIN';
    const supportEmail = 'k17mnk@gmail.com';

    const androidStoreUrl =
        'https://play.google.com/store/apps/details?id=com.kmin.stock_valuation_app';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.aboutApp),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
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
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    companyName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      t.companyDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.versionLabel(versionText),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (AppUpdateService.hasUpdate) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.orange.withAlpha(80)),
                      ),
                      child: Text(
                        t.updateAvailableBadge,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AppUpdateService.startImmediateUpdate();
                        },
                        child: Text(t.updateFromAbout),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.updateCheckInAboutHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                t.contact,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(t.emailInquiry),
              subtitle: const Text(supportEmail),
              onTap: () => _sendEmail(
                supportEmail,
                subject: t.appInquirySubject,
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                t.update,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.system_update_alt,
                color: AppUpdateService.hasUpdate ? Colors.red : null,
              ),
              title: Text(
                AppUpdateService.hasUpdate
                    ? t.updateAvailableMenuTitle
                    : t.checkForUpdates,
                style: TextStyle(
                  color: AppUpdateService.hasUpdate ? Colors.red : null,
                  fontWeight:
                      AppUpdateService.hasUpdate ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                AppUpdateService.hasUpdate
                    ? t.updateAvailableMenuSubtitle
                    : t.installLatestVersion,
              ),
              trailing: AppUpdateService.hasUpdate
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.red.withAlpha(80)),
                      ),
                      child: Text(
                        t.updateAvailableBadge,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
              onTap: () async {
                if (AppUpdateService.hasUpdate) {
                  await AppUpdateService.startImmediateUpdate();
                } else {
                  await _openUrl(androidStoreUrl);
                }
              },
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                t.misc,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(t.termsOfService),
              onTap: () => _showTextDialog(
                t.termsOfService,
                TermsText.content(context),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(t.privacyPolicy),
              onTap: () => _showTextDialog(
                t.privacyPolicy,
                PrivacyText.content(context),
                url: PrivacyText.url,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(t.openSourceLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: t.appTitle,
                applicationVersion: versionText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}