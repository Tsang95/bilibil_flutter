import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/user_session.dart';

void main() {
  test('UserSession parses account data without persisting password', () {
    final session = UserSession.fromJson(<String, dynamic>{
      'token': 'token-value',
      'member': <String, dynamic>{
        'id': 12,
        'username': 'account',
        'password': 'must-not-be-kept',
        'nickname': '昵称',
        'gold_balance': '8.5',
      },
    });

    expect(session.token, 'token-value');
    expect(session.user.id, 12);
    expect(session.user.goldBalance, 8.5);
    expect(session.user.toJson(), isNot(contains('password')));
  });

  test('UserSession preserves the legacy creator post count', () {
    final session = UserSession.fromJson(<String, dynamic>{
      'token': 'token-value',
      'member': <String, dynamic>{'media_post_num': '12'},
    });

    expect(session.user.mediaPostCount, 12);
    expect(session.user.toJson()['media_post_num'], 12);
  });
}
