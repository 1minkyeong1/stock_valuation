import 'package:flutter/widgets.dart';

class PrivacyText {
  static const String url = 'https://stock-privacy-policy.pages.dev/';

  static String content(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return isKo ? _ko : _en;
  }

  static const String _ko = '''
[개인정보처리방침]

본 개인정보처리방침은 주식적정가계산기(이하 "앱")에 적용되며,
KMIN(이하 "개발자")이 제공하는 서비스의 개인정보 처리 기준을 설명합니다.

1. 수집하는 정보
본 앱은 회원가입 기능을 제공하지 않으며, 이름, 생년월일, 전화번호 등
이용자를 직접 식별할 수 있는 개인정보를 앱 내에서 직접 수집하지 않습니다.

다만, 이용자가 문의를 위해 이메일을 보내는 경우,
이용자가 자발적으로 제공한 이메일 주소 및 문의 내용이 처리될 수 있습니다.

또한 본 앱은 광고 제공을 위해 Google AdMob 등 외부 서비스를 사용할 수 있으며,
이 과정에서 광고 식별자(ADID/IDFA), 기기 정보, 앱 사용 정보 등이
광고 제공 및 성과 측정을 위해 처리될 수 있습니다.

2. 정보의 이용 목적
- 앱 기능 제공 및 서비스 운영
- 광고 제공 및 광고 성과 측정
- 이용자 문의 응대 및 고객 지원
- 오류 확인, 안정성 개선 및 서비스 품질 향상

3. 보관 및 파기
개발자는 수집 또는 처리 목적 달성에 필요한 기간 동안만 관련 정보를 보관하며,
목적이 달성되었거나 더 이상 보관이 필요하지 않은 경우 지체 없이 삭제 또는 파기합니다.

이메일 문의 내용은 문의 대응, 기록 관리 및 분쟁 방지를 위해
필요한 범위 내에서만 일정 기간 보관될 수 있습니다.

4. 제3자 제공 및 외부 서비스
개발자는 이용자의 개인정보를 판매하지 않습니다.

다만 광고 제공, 앱 운영, 관련 법령 준수 등을 위해 필요한 범위에서
외부 서비스 제공자가 관련 정보를 처리할 수 있습니다.

예:
- Google AdMob 등 광고 서비스 제공자
- 법령에 따라 제공이 요구되는 관계 기관

5. 처리 위탁
개발자는 서비스 운영상 필요한 경우 일부 업무를 외부 서비스에 맡길 수 있으며,
이 경우 관련 법령에 따라 필요한 조치를 취합니다.

6. 이용자의 권리
이용자는 자신의 개인정보와 관련하여 열람, 정정, 삭제를 요청할 수 있으며,
아래 문의처를 통해 요청할 수 있습니다.

7. 보안 조치
개발자는 개인정보의 분실, 도난, 유출 또는 훼손을 방지하기 위해
합리적인 기술적·관리적 보호조치를 적용하도록 노력합니다.

8. 아동의 개인정보
본 앱은 아동을 대상으로 하지 않으며,
개발자가 아동의 개인정보가 수집되었음을 인지한 경우 관련 법령에 따라 필요한 조치를 취합니다.

9. 개인정보처리방침의 변경
본 방침은 관련 법령, 서비스 내용 또는 운영 정책의 변경에 따라 수정될 수 있으며,
변경 시 앱 또는 공개된 웹페이지를 통해 공지합니다.

10. 문의처
- 이메일: k17mnk@gmail.com
- 개발자: KMIN
- 앱명: 주식적정가계산기

부칙
본 방침은 2026-04-01부터 적용됩니다.
''';

  static const String _en = '''
[Privacy Policy]

This Privacy Policy applies to the Stock Fair Value Calculator app (the “App”)
provided by KMIN (the “Developer”) and explains how information is handled.

1. Information We Collect
The App does not provide account registration and does not directly collect
personally identifiable information such as name, date of birth, or phone number
from users within the App.

However, if a user contacts us by email, the email address and inquiry content
voluntarily provided by the user may be processed.

In addition, the App may use external services such as Google AdMob to provide ads.
In this process, advertising identifiers (ADID/IDFA), device information,
and app usage information may be processed for advertising and performance measurement.

2. Purpose of Use
- To provide app features and operate the service
- To provide advertisements and measure ad performance
- To respond to user inquiries and provide customer support
- To check errors, improve stability, and enhance service quality

3. Retention and Deletion
The Developer retains related information only for as long as necessary
to fulfill the purpose of collection or processing, and deletes or destroys it
without delay when it is no longer needed.

Email inquiry records may be retained for a limited period as necessary
for customer support, record keeping, and dispute prevention.

4. Third-Party Processing and External Services
The Developer does not sell users’ personal information.

However, to the extent necessary for advertising, app operation,
or compliance with applicable laws, external service providers may process related information.

Examples:
- Advertising service providers such as Google AdMob
- Relevant authorities when disclosure is required by law

5. Outsourcing of Processing
Where necessary for service operation, the Developer may entrust certain tasks
to external services and will take necessary measures in accordance with applicable laws.

6. User Rights
Users may request access, correction, or deletion of their personal information
through the contact information below.

7. Security Measures
The Developer strives to apply reasonable technical and administrative safeguards
to prevent loss, theft, leakage, or damage of personal information.

8. Children’s Privacy
The App is not directed to children. If the Developer becomes aware
that children’s personal information has been collected,
necessary measures will be taken in accordance with applicable laws.

9. Changes to This Policy
This Policy may be revised due to changes in laws, service contents,
or operational policies. Any updates will be announced through the App
or the public webpage.

10. Contact
- Email: k17mnk@gmail.com
- Developer: KMIN
- App Name: Stock Fair Value Calculator

Supplementary Provision
This Policy takes effect on 2026-04-01.
''';
}