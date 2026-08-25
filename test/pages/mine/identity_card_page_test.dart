import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/pages/mine/identity_card_page.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final store = Get.put(UserStore());
    store.user.value = UserInfo.fromJson(const <String, dynamic>{
      'id': 1,
      'username': 'testAccount',
    });
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets(
    'identity card does not block a logged-in user without password',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: SizedBox.expand())),
      );
      Get.dialog<void>(const IdentityCardDialog());
      await tester.pumpAndSettle();

      expect(find.text('本次会话没有可用的身份卡凭证'), findsNothing);
    },
  );
}
