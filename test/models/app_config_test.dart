import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/app_config.dart';

void main() {
  test('AppConfig safely parses mixed legacy numeric types', () {
    final config = AppConfig.fromJson(<String, dynamic>{
      'on_line': 'https://example.com',
      'withdrawal_fee': '1.25',
      'usdt_exchange_rate': 7,
      'share_domain': <String>['a.example', 'b.example'],
    });

    expect(config.onlineUrl, 'https://example.com');
    expect(config.withdrawalFee, 1.25);
    expect(config.usdtExchangeRate, 7);
    expect(config.shareDomains, ['a.example', 'b.example']);
  });

  test('AppConfig parses legacy JSON encoded share domains', () {
    final config = AppConfig.fromJson(<String, dynamic>{
      'share_domain': '["a.example", "b.example", ""]',
    });

    expect(config.shareDomains, ['a.example', 'b.example']);
  });
}
