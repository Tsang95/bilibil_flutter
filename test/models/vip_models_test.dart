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

  test('recharge order preserves the legacy USDT payment payload', () {
    final order = RechargeOrder.fromJson(<String, dynamic>{
      'pay_url': '',
      'amount': '100',
      'coin': 'USDT',
      'address': 'TRC20-address',
      'usdt_price': '5.25',
    });

    expect(order.amount, 100);
    expect(order.coin, 'USDT');
    expect(order.address, 'TRC20-address');
    expect(order.usdtPrice, 5.25);
    expect(order.isUsdt, isTrue);
  });

  test('withdraw record normalizes legacy link, amount and status fields', () {
    final record = WithdrawRecord.fromJson(<String, dynamic>{
      'id': '9',
      'link_type': '1',
      'coin_address': 'T-address',
      'gold_num': '1000',
      'real_num': '50.0',
      'exchange_rate': '0.05',
      'real_coin': '50',
      'status': '-1',
      'notes': '地址错误',
    });

    expect(record.linkType, WithdrawLinkType.trc20);
    expect(record.actualAmount, 50);
    expect(record.status, WithdrawStatus.failed);
    expect(record.status.label, '提现失败');
  });
}
