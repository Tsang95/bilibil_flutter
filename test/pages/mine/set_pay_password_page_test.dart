import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/pages/mine/set_pay_password_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('payment password page preserves the legacy two-field form', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: SetPayPasswordPage()));

    expect(find.text('设置支付密码'), findsOneWidget);
    expect(find.text('支付密码'), findsOneWidget);
    expect(find.text('确认支付密码'), findsOneWidget);
    expect(find.text('请输入6位数字支付密码'), findsOneWidget);
    expect(find.text('请再次输入支付密码'), findsOneWidget);
    expect(find.text('遇到问题，联系客服'), findsOneWidget);
    expect(find.byType(LegacyTextField), findsNWidgets(2));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.widget<TextField>(find.byType(TextField).first).maxLength, 6);
  });
}
