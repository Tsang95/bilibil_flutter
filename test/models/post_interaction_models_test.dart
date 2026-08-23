import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/charge_member.dart';
import 'package:b_flutter/models/charge_subscription_product.dart';
import 'package:b_flutter/models/common_barrage.dart';

void main() {
  test('common barrage accepts legacy identifiers and content aliases', () {
    final barrage = CommonBarrage.fromJson(<String, dynamic>{
      'id': '12',
      'text': '  好看爱看  ',
    });

    expect(barrage.id, 12);
    expect(barrage.content, '好看爱看');
  });

  test('charge subscription product accepts legacy numeric values', () {
    final product = ChargeSubscriptionProduct.fromJson(<String, dynamic>{
      'id': '8',
      'name': '包月充电',
      'coin': '30.5',
      'old_coin': 40,
    });

    expect(product.id, 8);
    expect(product.name, '包月充电');
    expect(product.price, 30.5);
    expect(product.originalPrice, 40);
  });

  test('charge member preserves the legacy subscription duration', () {
    final member = ChargeMember.fromJson(<String, dynamic>{
      'id': '9',
      'nickname': 'bilibili乱伦少女精选',
      'head_sculpture': '/avatars/9.png',
      'is_sub': '12',
    });

    expect(member.id, 9);
    expect(member.nickname, 'bilibili乱伦少女精选');
    expect(member.avatarUrl, '/avatars/9.png');
    expect(member.subscriptionDays, 12);
  });
}
