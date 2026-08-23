abstract final class AppEnvironment {
  static const String channel = String.fromEnvironment(
    'APP_CHANNEL',
    defaultValue: 'android_active',
  );

  static const String apiDomains = String.fromEnvironment('API_DOMAINS');
  static const String webSocketUrl = String.fromEnvironment('WS_URL');
  static const bool enableRequestEncryption = bool.fromEnvironment(
    'ENABLE_REQUEST_ENCRYPTION',
    defaultValue: true,
  );
  static const String apiSigningKey = String.fromEnvironment('API_SIGNING_KEY');
  static const String apiResponseAesKey = String.fromEnvironment(
    'API_RESPONSE_AES_KEY',
  );
  static const String apiResponseIvPrefix = String.fromEnvironment(
    'API_RESPONSE_IV_PREFIX',
  );
  static const String identityCardIvSuffix = String.fromEnvironment(
    'IDENTITY_CARD_IV_SUFFIX',
  );
  static const String videoSigningKey = String.fromEnvironment(
    'VIDEO_SIGNING_KEY',
  );

  static List<String> get configuredApiDomains => apiDomains
      .split(',')
      .map((domain) => domain.trim())
      .where((domain) => domain.isNotEmpty)
      .toList(growable: false);
}
