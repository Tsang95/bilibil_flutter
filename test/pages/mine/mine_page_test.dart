import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/models/user_session.dart';
import 'package:b_flutter/pages/mine/mine_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  late UserStore userStore;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TokenManager.instance.clear();
    userStore = Get.put<UserStore>(UserStore());
  });

  tearDown(() async {
    await TokenManager.instance.clear();
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('未登录时隐藏旧版发布与广告推广卡', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: MinePage())),
    );

    expect(
      find.byKey(const ValueKey<String>('mine_creator_promotion')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('mine_ads_promotion')),
      findsNothing,
    );
    expect(find.text('登录解锁更多权限'), findsOneWidget);
  });

  testWidgets('我的页面在小屏上保持分组层级并可完整滚动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: MinePage())),
    );

    expect(find.text('我的'), findsNothing);
    expect(find.text('常用服务'), findsOneWidget);
    final pageList = find.byType(ListView);
    expect(find.text('更多服务'), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      await tester.drag(pageList, const Offset(0, -300));
      await tester.pump();
    }
    expect(find.text('官方交流群'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已登录首页恢复个人空间、关注列表和 VIP 角标', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await userStore.activateSession(
      UserSession(
        token: 'mine-test-token',
        user: UserInfo.fromJson(<String, dynamic>{
          'id': 88,
          'username': 'mine-user',
          'nickname': '测试用户',
          'movie_vip_level': 3,
          'movie_vip_time': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
        }),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: <GetPage<dynamic>>[
          GetPage<dynamic>(
            name: AppRoutes.userProfile,
            page: () => const Scaffold(body: Text('个人空间页')),
          ),
          GetPage<dynamic>(
            name: AppRoutes.myFans,
            page: () =>
                Scaffold(body: Text('关注类型:${(Get.arguments as Map)['type']}')),
          ),
        ],
        home: const Scaffold(body: MinePage()),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('mine_video_vip_badge')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('mine_creator_promotion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('mine_ads_promotion')),
      findsOneWidget,
    );

    await tester.tap(find.text('个人空间'));
    await tester.pumpAndSettle();
    expect(find.text('个人空间页'), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的关注'));
    await tester.pumpAndSettle();
    expect(find.text('关注类型:1'), findsOneWidget);
  });
}
