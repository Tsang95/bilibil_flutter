import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
import 'package:b_flutter/stores/user_store.dart';

const _creatorProducts = <VipProduct>[
  VipProduct(
    id: 1,
    name: '初级UP主',
    days: 30,
    price: 100,
    oldPrice: 200,
    commentLimit: 0,
    privateMessageLimit: 0,
    postLimit: 5,
    categoryNames: <String>['影视', '动漫'],
  ),
  VipProduct(
    id: 2,
    name: '超级UP主',
    days: 90,
    price: 260,
    oldPrice: 600,
    commentLimit: 0,
    privateMessageLimit: 0,
    postLimit: 20,
    categoryNames: <String>['全部圈子'],
  ),
];

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
    final loading = Completer<List<VipProduct>>();
    await tester.pumpWidget(
      GetMaterialApp(
        home: VipCenterPage(
          loadProducts: ({bool forceRefresh = false}) => loading.future,
        ),
      ),
    );

    expect(find.text('会员中心'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('vip_account_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('vip_product_loading_grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('vip_product_skeleton_5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('vip_purchase_bar')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('creator entry uses the legacy certification title', (
    tester,
  ) async {
    final loading = Completer<List<VipProduct>>();
    await tester.pumpWidget(
      GetMaterialApp(
        home: VipCenterPage(
          initialType: VipType.creator,
          loadProducts: ({bool forceRefresh = false}) => loading.future,
        ),
      ),
    );

    expect(find.text('认证中心'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('certification layout keeps legacy hierarchy and selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        home: VipCenterPage(
          initialType: VipType.creator,
          loadProducts: ({bool forceRefresh = false}) async => _creatorProducts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('初级UP主'), findsWidgets);
    expect(find.text('超级UP主'), findsOneWidget);
    expect(find.textContaining('/月'), findsNWidgets(2));
    expect(find.text('可创作圈子：影视 动漫'), findsOneWidget);
    expect(find.text('发帖次数：+5'), findsOneWidget);
    expect(find.text('初级UP主:100元'), findsOneWidget);

    final accountCard = tester.getRect(
      find.byKey(const ValueKey<String>('vip_account_card')),
    );
    final productGrid = tester.getRect(
      find.byKey(const ValueKey<String>('vip_product_grid')),
    );
    final purchaseBar = tester.getRect(
      find.byKey(const ValueKey<String>('vip_purchase_bar')),
    );
    expect(accountCard.height, 92);
    expect(productGrid.top - accountCard.bottom, 20);
    expect(purchaseBar.height, 60);
    expect(purchaseBar.bottom, 844);

    await tester.tap(find.byKey(const ValueKey<String>('vip_product_1')));
    await tester.pump();
    expect(find.text('超级UP主:260元'), findsOneWidget);
    expect(find.text('可创作圈子：全部圈子'), findsOneWidget);
    expect(find.text('发帖次数：+20'), findsOneWidget);
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
