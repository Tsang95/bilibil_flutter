import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
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

  testWidgets('VIP centre keeps the legacy hidden-tab single page', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: VipCenterPage()));

    expect(find.text('会员中心'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('creator entry uses the legacy certification title', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: VipCenterPage(initialType: VipType.creator)),
    );

    expect(find.text('认证中心'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('VIP purchase prompts use the legacy two-action dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: LegacyMessageDialog(
            title: '提示',
            message: '余额不足，请前往充值',
            cancelLabel: '取消',
            confirmLabel: '确认',
            onCancel: () {},
            onConfirm: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('legacy_message_dialog_panel')),
      findsOneWidget,
    );
    expect(find.text('余额不足，请前往充值'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
