import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/pages/vip/recharge_usdt_page.dart';

void main() {
  testWidgets('USDT recharge preserves the legacy payment card and notices', (
    tester,
  ) async {
    const order = RechargeOrder(
      url: '',
      amount: 100,
      coin: 'USDT',
      address: 'TRC20-address',
      usdtPrice: 5.25,
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: RechargeUsdtPage(order: order)),
    );

    expect(find.text('USDT充值'), findsOneWidget);
    expect(find.text('5.25USDT'), findsOneWidget);
    expect(find.text('官方收款钱包地址'), findsOneWidget);
    expect(find.text('USDT/TRC20'), findsOneWidget);
    expect(find.textContaining('30:00'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('TRC20-address'), findsOneWidget);
    expect(find.text('保存二维码'), findsOneWidget);
    expect(find.text('复制地址'), findsOneWidget);
    expect(find.text('温馨提示'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('USDT recharge rejects a missing payment address', (
    tester,
  ) async {
    const order = RechargeOrder(
      url: '',
      amount: 0,
      coin: '',
      address: '',
      usdtPrice: 0,
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: RechargeUsdtPage(order: order)),
    );

    expect(find.text('订单信息无效'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
