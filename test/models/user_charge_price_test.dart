import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/user_charge_price.dart';
import 'package:b_flutter/models/user_info.dart';

void main() {
  test('charge price accepts legacy string and numeric values', () {
    final price = UserChargePrice.fromJson(<String, dynamic>{
      'month': '10',
      'quarter': 20,
      'year': 30.0,
    });

    expect(price.month, 10);
    expect(price.quarter, 20);
    expect(price.year, 30);
  });

  test('user profile copy keeps unrelated account state', () {
    final user = UserInfo.fromJson(<String, dynamic>{
      'id': 1,
      'nickname': '旧昵称',
      'gold_balance': 42,
      'coin_num': 3,
      'pay_pwd': 1,
    });
    final updated = user.copyWith(nickname: '新昵称', gender: 1);

    expect(updated.nickname, '新昵称');
    expect(updated.gender, 1);
    expect(updated.goldBalance, 42);
    expect(updated.coinCount, 3);
    expect(updated.hasPayPassword, isTrue);
  });
}
