import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/app_version.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_forum_post_card.dart';
import 'package:b_flutter/pages/home/components/home_latest_post_card.dart';
import 'package:b_flutter/pages/home/components/home_movie_post_card.dart';
import 'package:b_flutter/pages/home/components/home_portrait_post_card.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/components/home_startup_dialogs.dart';
import 'package:b_flutter/pages/home/home_top_menu_page.dart';
import 'package:b_flutter/pages/game/game_page.dart';
import 'package:b_flutter/pages/mine/mine_page.dart';
import 'package:b_flutter/pages/message/message_page.dart';
import 'package:b_flutter/pages/posts/components/post_tag_post_card.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  final post = PostSummary.fromJson(<String, dynamic>{
    'id': 1,
    'title': '用于验证首页多种布局的测试标题',
    'describe': '内容说明',
    'duration': 125,
    'views_num': 12345,
    'collect_num': 99,
    'sales_num': 10,
    'member_obj': <String, Object>{'nickname': '测试作者'},
    'plate_two_obj': <String, Object>{'name': '测试分区'},
  });

  testWidgets('home card variants fit their legacy dimensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 175,
                  height: 177,
                  child: HomePostCard(post: post),
                ),
                SizedBox(
                  width: 175,
                  height: 168,
                  child: PostTagPostCard(post: post),
                ),
                SizedBox(
                  width: 115,
                  height: 228,
                  child: HomePortraitPostCard(post: post),
                ),
                SizedBox(
                  width: 110,
                  height: 180,
                  child: HomeMoviePostCard(post: post, imageHeight: 146),
                ),
                SizedBox(width: 375, child: HomeLatestPostCard(post: post)),
                SizedBox(width: 375, child: HomeForumPostCard(post: post)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('UP'), findsOneWidget);
    expect(find.text('看正片'), findsNothing);
    expect(find.text('免费'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('home_post_cover_1')))
          .height,
      98,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('home_post_information_1')),
          )
          .height,
      70,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('home_portrait_cover_1')))
          .height,
      153,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('home_portrait_information_1')),
          )
          .height,
      70,
    );
  });

  testWidgets('latest card fits a narrow home viewport', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, child: HomeLatestPostCard(post: post)),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('normal card tolerates the legacy grid rounding on 360 width', (
    tester,
  ) async {
    const gridItemWidth = (360 - 26 - 6) / 2;
    const gridItemHeight = gridItemWidth * 177 / 175;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: gridItemWidth,
              height: gridItemHeight,
              child: HomePostCard(post: post),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('home_post_cover_1')))
          .height,
      98,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('home_post_information_1')),
          )
          .height,
      closeTo(gridItemHeight - 98, 0.01),
    );
  });

  testWidgets('all home post layouts show coin and VIP access badges', (
    tester,
  ) async {
    final coinPost = PostSummary.fromJson(<String, dynamic>{
      'id': 2,
      'title': '金币内容',
      'price': '2.5',
      'is_buy': 1,
      'cover_images': <String>['https://example.test/coin-cover.jpg'],
    });
    final vipPost = PostSummary.fromJson(<String, dynamic>{
      'id': 3,
      'title': 'VIP内容',
      'is_buy': 2,
      'is_vip_watch': 1,
      'cover_images': <String>['https://example.test/vip-cover.jpg'],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 175,
                  height: 177,
                  child: HomePostCard(post: coinPost),
                ),
                SizedBox(
                  width: 115,
                  height: 228,
                  child: HomePortraitPostCard(post: coinPost),
                ),
                SizedBox(
                  width: 110,
                  height: 180,
                  child: HomeMoviePostCard(post: vipPost, imageHeight: 146),
                ),
                SizedBox(width: 375, child: HomeLatestPostCard(post: vipPost)),
                SizedBox(width: 375, child: HomeForumPostCard(post: coinPost)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2.5金币'), findsNWidgets(3));
    expect(find.text('VIP'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('summary access type follows legacy is_buy semantics', () {
    final locked = PostSummary.fromJson(<String, dynamic>{
      'price': 8,
      'is_buy': 1,
    });
    final purchased = PostSummary.fromJson(<String, dynamic>{
      'price': 8,
      'is_buy': 0,
    });
    final vip = PostSummary.fromJson(<String, dynamic>{'is_buy': 2});

    expect(locked.isPurchased, isFalse);
    expect(locked.accessBadgeText, '8金币');
    expect(purchased.isPurchased, isTrue);
    expect(purchased.accessBadgeText, isEmpty);
    expect(vip.accessBadgeText, 'VIP');
  });

  testWidgets(
    'version dialog keeps legacy width and caps height at half viewport',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: HomeVersionDialog(
                version: AppVersion.fromJson(<String, dynamic>{
                  'title': '版本更新',
                  'describe': '优化播放体验',
                  'version_no': 2,
                }),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(
        find.byKey(const Key('home_version_dialog_card')),
      );
      expect(size.width, 320);
      expect(size.height, lessThanOrEqualTo(400));
      expect(size.height, lessThan(400));
    },
  );

  testWidgets('home top menu keeps the legacy four-column partition layout', (
    tester,
  ) async {
    final categories = List<HomeCategory>.generate(
      4,
      (index) => HomeCategory.fromJson(<String, dynamic>{
        'id': index + 1,
        'name': '分区${index + 1}',
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeTopMenuPage(
          arguments: HomeTopMenuArguments(
            categories: categories,
            banners: const <BannerItem>[],
            contentAds: const <BannerItem>[],
          ),
        ),
      ),
    );

    expect(find.text('分区'), findsOneWidget);
    expect(find.text('分区1'), findsOneWidget);
    expect(find.text('分区4'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mine landing restores the legacy account and service chrome', (
    tester,
  ) async {
    Get.put(UserStore());
    addTearDown(Get.delete<UserStore>);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MinePage())),
    );

    expect(find.text('请登录'), findsOneWidget);
    expect(find.text('登录解锁更多权限'), findsOneWidget);
    expect(find.text('认证中心'), findsOneWidget);
    expect(find.text('会员中心'), findsOneWidget);
    expect(find.text('推广中心'), findsOneWidget);
    expect(find.text('发布你的第一个视频'), findsOneWidget);
    expect(find.text('一键自助发布广告引流'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('message landing restores the legacy three-entry navigation', (
    tester,
  ) async {
    Get.put(UserStore());
    addTearDown(Get.delete<UserStore>);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MessagePage())),
    );

    expect(find.text('站内信'), findsOneWidget);
    expect(find.text('评论'), findsOneWidget);
    expect(find.text('联系客服'), findsOneWidget);
    expect(find.text('登录后查看消息'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('anonymous game landing preserves lobby and prompts for login', (
    tester,
  ) async {
    Get.put(UserStore());
    addTearDown(Get.delete<UserStore>);

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: GamePage())),
    );

    expect(find.text('游戏'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('game_app_bar'))).height,
      48,
    );
    expect(
      tester.getCenter(find.text('游戏')).dx,
      moreOrLessEquals(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
      ),
    );
    expect(find.text('请登录'), findsOneWidget);
    expect(find.text('￥'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('充值'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('充值'));
    await tester.pumpAndSettle();

    expect(find.text('提示'), findsOneWidget);
    expect(find.text('您还未登录，请先登录!'), findsOneWidget);
    expect(find.text('去登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game exit prompt preserves the legacy two-button layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (dialogContext) => LegacyMessageDialog(
                  title: '提示',
                  message: '确定退出游戏？',
                  cancelLabel: '再玩会',
                  confirmLabel: '确定',
                  onCancel: () => Navigator.of(dialogContext).pop(false),
                  onConfirm: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('提示'), findsOneWidget);
    expect(find.text('确定退出游戏？'), findsOneWidget);
    expect(find.text('再玩会'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('legacy_message_dialog_panel')),
          )
          .width,
      320,
    );
    expect(tester.takeException(), isNull);
  });
}
