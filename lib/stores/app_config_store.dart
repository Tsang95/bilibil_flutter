import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/models/app_config.dart';

final class AppConfigStore {
  AppConfigStore._();

  static final AppConfigStore instance = AppConfigStore._();
  static const String _configKey = 'app_config_v2';
  static const String _domainKey = 'last_successful_api_domain_v2';
  static const String _legacyConfigKey = 'appConfig';
  static const String _legacyDomainKey = 'apiUrl';

  AppConfig? _config;
  String _domain = '';

  AppConfig? get config => _config;
  String get domain => _domain;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _domain = preferences.getString(_domainKey) ?? '';
    var rawConfig = preferences.getString(_configKey);
    if (_domain.isEmpty || rawConfig == null || rawConfig.isEmpty) {
      final migratedConfig = await _migrateLegacyConfig(preferences);
      if (rawConfig == null || rawConfig.isEmpty) {
        rawConfig = migratedConfig;
      }
    }
    if (rawConfig == null || rawConfig.isEmpty) return;
    try {
      final json = jsonDecode(rawConfig);
      if (json is Map) {
        _config = AppConfig.fromJson(Map<String, dynamic>.from(json));
      }
    } on FormatException {
      await preferences.remove(_configKey);
    }
  }

  Future<String?> _migrateLegacyConfig(SharedPreferences preferences) async {
    final legacyDomain = preferences.getString(_legacyDomainKey)?.trim() ?? '';
    final legacyConfig = preferences.getString(_legacyConfigKey);

    if (_domain.isEmpty && legacyDomain.isNotEmpty) {
      _domain = legacyDomain;
      await preferences.setString(_domainKey, legacyDomain);
    }
    if (legacyConfig == null || legacyConfig.isEmpty) return null;

    try {
      final decoded = jsonDecode(legacyConfig);
      if (decoded is! Map) return null;
      final normalized = AppConfig.fromJson(Map<String, dynamic>.from(decoded));
      final rawConfig = jsonEncode(normalized.toJson());
      await preferences.setString(_configKey, rawConfig);
      return rawConfig;
    } on FormatException {
      return null;
    }
  }

  Future<void> save({required String domain, required AppConfig config}) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      preferences.setString(_domainKey, domain),
      preferences.setString(_configKey, jsonEncode(config.toJson())),
    ]);
    _domain = domain;
    _config = config;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      preferences.remove(_domainKey),
      preferences.remove(_configKey),
    ]);
    _domain = '';
    _config = null;
  }
}
