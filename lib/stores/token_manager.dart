import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class TokenManager {
  TokenManager._();

  static final TokenManager instance = TokenManager._();
  static const String _storageKey = 'auth_token';

  String _token = '';

  String get token => _token;
  bool get hasToken => _token.isNotEmpty;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _token = preferences.getString(_storageKey) ?? '';
    if (_token.isNotEmpty) return;

    // One-time upgrade path from the legacy SpUtil `user` object. Only the
    // token is migrated; legacy member/password data is intentionally ignored.
    final legacySession = preferences.getString('user');
    if (legacySession == null || legacySession.isEmpty) return;
    try {
      final decoded = jsonDecode(legacySession);
      if (decoded is Map && decoded['token'] is String) {
        final migratedToken = (decoded['token'] as String).trim();
        if (migratedToken.isNotEmpty) await setToken(migratedToken);
      }
    } on FormatException {
      // Invalid legacy state behaves like a logged-out session.
    }
  }

  Future<void> setToken(String token) async {
    final normalizedToken = token.trim();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, normalizedToken);
    _token = normalizedToken;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    _token = '';
  }
}
