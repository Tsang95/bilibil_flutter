import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/vip_models.dart';

void main() {
  test('VIP product accepts legacy product fields and creator circles', () {
    final product = VipProduct.fromJson(<String, dynamic>{
      'id': '7',
      'name': '超级会员',
      'real_day': '30',
      'price': '99.5',
      'old_price': 120,
      'post_num': '12',
      'circleObj': <Map<String, String>>[
        <String, String>{'name': '影视'},
        <String, String>{'name': '原创'},
      ],
    });

    expect(product.id, 7);
    expect(product.price, 99.5);
    expect(product.categoryNames, <String>['影视', '原创']);
  });

  test('wallet and recharge records retain numeric-string legacy fields', () {
    final wallet = WalletChangeRecord.fromJson(<String, dynamic>{
      'id': '1',
      'gold_num': '-2.5',
      'created_at': '2026-08-25',
    });
    final order = RechargeHistoryRecord.fromJson(<String, dynamic>{
      'id': 2,
      'money': '30',
      'pay_status': '1',
    });

    expect(wallet.amount, -2.5);
    expect(order.amount, 30);
    expect(order.isPaid, isTrue);
  });
}
