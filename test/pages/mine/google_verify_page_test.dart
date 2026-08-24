import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/google_verify_data.dart';
import 'package:b_flutter/pages/mine/google_binded_page.dart';
import 'package:b_flutter/pages/mine/google_verify_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('Google verification preserves the legacy binding form', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: GoogleVerifyPage(
          loadSecret: () async =>
              const GoogleVerifyData(key: 'ABCD-1234', url: ''),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('谷歌秘钥'), findsOneWidget);
    expect(find.text('ABCD-1234'), findsOneWidget);
    expect(find.text('复制'), findsOneWidget);
    expect(find.text('谷歌验证码'), findsAtLeastNWidgets(2));
    expect(find.text('绑定'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Google bound page retains its status and service link', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: GoogleBindedPage()));

    expect(find.text('已绑定'), findsOneWidget);
    expect(find.text('如果您有任何问题请联系在线客服'), findsOneWidget);
  });
}
