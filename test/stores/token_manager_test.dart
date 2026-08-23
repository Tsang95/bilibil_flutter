import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/stores/token_manager.dart';

void main() {
  test('migrates only token from the legacy user object', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user': jsonEncode(<String, Object>{
        'token': 'legacy-token',
        'member': <String, Object>{'password': 'legacy-password'},
      }),
    });
    await TokenManager.instance.clear();

    await TokenManager.instance.initialize();

    expect(TokenManager.instance.token, 'legacy-token');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('auth_token'), 'legacy-token');
    expect(preferences.getString('auth_token'), isNot(contains('password')));
  });
}
