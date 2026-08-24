import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/pages/mine/change_password_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('change password page preserves legacy form fields', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: ChangePasswordPage()));

    expect(find.text('修改登录密码'), findsOneWidget);
    expect(find.text('旧密码'), findsOneWidget);
    expect(find.text('新密码'), findsOneWidget);
    expect(find.text('确认密码'), findsOneWidget);
    expect(find.text('遇到问题，联系客服'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });
}
