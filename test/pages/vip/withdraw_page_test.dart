import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_pay_password_dialog.dart';
import 'package:b_flutter/pages/vip/withdraw_page.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<UserStore>(UserStore());
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('withdraw page preserves the legacy USDT form', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: WithdrawPage()));

    expect(find.text('提现'), findsOneWidget);
    expect(find.text('提现记录'), findsOneWidget);
    expect(find.text('ERC20'), findsOneWidget);
    expect(find.text('TRC20'), findsOneWidget);
    expect(find.text('提币地址'), findsOneWidget);
    expect(find.text('上传二维码'), findsOneWidget);
    expect(find.text('最低提现金额数量1000'), findsOneWidget);
    expect(find.text('确认提现'), findsOneWidget);
  });

  testWidgets('payment password dialog keeps six digit legacy input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: LegacyPayPasswordDialog())),
    );

    expect(
      find.byKey(const ValueKey<String>('legacy_pay_password_dialog')),
      findsOneWidget,
    );
    expect(find.text('请输入支付密码'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
  });
}
