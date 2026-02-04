class AppConfig {
  // 빌드/실행 시 주입: --dart-define=DATA_GO_KR_KEY=...
  static const dataGoKrKey = String.fromEnvironment('DATA_GO_KR_KEY');

  // 필요하면 광고ID도 이런 식으로 추가 가능
  // static const admobAppId = String.fromEnvironment('ADMOB_APP_ID');
}