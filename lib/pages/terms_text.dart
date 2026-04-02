import 'package:flutter/widgets.dart';

class TermsText {
  static String content(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return isKo ? _ko : _en;
  }

  static const String _ko = '''
[이용약관]

제1조(목적)
본 약관은 제작자(이하 "회사")가 제공하는 주식 적정가 계산기 앱(이하 "서비스")의 이용과 관련하여 회사와 이용자 간 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조(정의)
1. "서비스"란 회사가 제공하는 모바일 애플리케이션 및 관련 기능을 의미합니다.
2. "이용자"란 본 약관에 따라 서비스를 이용하는 자를 말합니다.

제3조(약관의 효력 및 변경)
회사는 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다. 변경 시 앱 내 공지 또는 업데이트를 통해 안내할 수 있습니다.

제4조(서비스 제공 및 변경)
회사는 서비스의 내용(기능, UI, 데이터 제공 방식 등)을 운영상/기술상 필요에 따라 변경할 수 있습니다.

제5조(면책)
1. 서비스는 투자 조언이 아니며, 제공 정보는 참고용입니다.
2. 회사는 외부 데이터 제공자 또는 네트워크 장애 등 회사의 통제 범위를 벗어난 사유로 인한 손해에 대해 책임을 지지 않습니다.
3. 이용자의 투자 판단 및 결과에 대한 책임은 이용자 본인에게 있습니다.

제6조(지식재산권)
서비스 및 관련 저작물의 권리는 회사에 귀속됩니다.

제7조(준거법 및 관할)
본 약관은 대한민국 법령을 준거법으로 하며, 분쟁은 민사소송법에 따른 관할 법원에서 해결합니다.

부칙
본 약관은 2026-04-01부터 적용됩니다.
''';

  static const String _en = '''
[Terms of Service]

Article 1 (Purpose)
These Terms of Service set forth the rights, obligations, and responsibilities
between the provider (the “Company”) and users in relation to the use of
the Stock Fair Value Calculator app (the “Service”).

Article 2 (Definitions)
1. “Service” refers to the mobile application and related features provided by the Company.
2. “User” refers to a person who uses the Service in accordance with these Terms.

Article 3 (Effect and Changes of the Terms)
The Company may revise these Terms to the extent permitted by applicable laws.
Any changes may be announced through notices within the App or through updates.

Article 4 (Provision and Changes of the Service)
The Company may change the contents of the Service
(including features, UI, and data delivery methods)
when necessary for operational or technical reasons.

Article 5 (Disclaimer)
1. The Service does not constitute investment advice, and the provided information is for reference only.
2. The Company is not liable for damages caused by reasons beyond its control,
including issues with external data providers or network failures.
3. Users are solely responsible for their own investment decisions and outcomes.

Article 6 (Intellectual Property Rights)
All rights to the Service and related works belong to the Company.

Article 7 (Governing Law and Jurisdiction)
These Terms are governed by the laws of the Republic of Korea,
and any disputes shall be resolved by the court with jurisdiction
under the Civil Procedure Act of Korea.

Supplementary Provision
These Terms take effect on 2026-04-01.
''';
}