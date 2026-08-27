import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/user_profile.dart';
import 'package:b_flutter/pages/posts/components/user_profile_post_card.dart';
import 'package:b_flutter/pages/posts/user_profile_page.dart';
import 'package:b_flutter/pages/posts/user_profile_video_page.dart';

void main() {
  tearDown(Get.reset);

  test('legacy profile video types keep their endpoint values and titles', () {
    expect(UserProfileVideoType.values.map((type) => type.apiValue), <int>[
      1,
      2,
      3,
      4,
    ]);
    expect(UserProfileVideoType.values.map((type) => type.title), <String>[
      '点赞视频',
      '购买视频',
      '收藏视频',
      '投币视频',
    ]);
  });

  testWidgets('个人空间资料头部在窄屏保持清晰层级', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const profile = UserProfile(
      id: 88,
      nickname: '昵称很长也不会挤压操作区域的测试用户',
      avatarUrl: '',
      backgroundUrl: '',
      signature: '这是一段较长的个人签名，用来确认个人空间在窄屏设备上仍然能够保持协调。',
      fanCount: 1200,
      workCount: 36,
      likeCount: 9800,
      isFollowing: false,
      isSubscribed: false,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: UserProfileHeader(
            profile: profile,
            isCurrentUser: false,
            following: false,
            onFollow: () {},
            onMessage: () {},
            onCharge: () {},
            onEdit: () {},
          ),
        ),
      ),
    );

    expect(find.text('ID：88'), findsOneWidget);
    expect(find.text('粉丝'), findsOneWidget);
    expect(find.text('作品'), findsOneWidget);
    expect(find.text('获赞'), findsOneWidget);
    expect(find.text('充电'), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    final signatureText = tester.widget<Text>(find.text(profile.signature));
    expect(signatureText.maxLines, isNull);
    final headerRect = tester.getRect(find.byType(UserProfileHeader));
    final cardRect = tester.getRect(
      find.byKey(const ValueKey<String>('user_profile_card')),
    );
    expect(headerRect.bottom - cardRect.bottom, closeTo(8, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('自己的个人空间保留大图标点击区和编辑按钮边距', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: UserProfileHeader(
            profile: const UserProfile(
              id: 88,
              nickname: '测试用户',
              avatarUrl: '',
              backgroundUrl: '',
              signature: '个人签名',
              fanCount: 12,
              workCount: 3,
              likeCount: 45,
              isFollowing: false,
              isSubscribed: false,
            ),
            isCurrentUser: true,
            following: false,
            onFollow: () {},
            onMessage: () {},
            onCharge: () {},
            onEdit: () {},
          ),
        ),
      ),
    );

    final backIcon = find.byIcon(CupertinoIcons.chevron_back);
    final backInk = find.ancestor(of: backIcon, matching: find.byType(Ink));
    expect(tester.getSize(backInk).width, 44);
    expect(tester.getSize(backInk).height, 44);

    final editRect = tester.getRect(
      find.widgetWithText(OutlinedButton, '编辑资料'),
    );
    final editIconRect = tester.getRect(find.byIcon(CupertinoIcons.pencil));
    final editTextRect = tester.getRect(find.text('编辑资料'));
    expect(editIconRect.left - editRect.left, greaterThanOrEqualTo(20));
    expect(editRect.right - editTextRect.right, greaterThanOrEqualTo(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('不同状态栏安全区下资料卡与页签间距保持一致', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const profile = UserProfile(
      id: 88,
      nickname: '测试用户',
      avatarUrl: '',
      backgroundUrl: '',
      signature: '这是一段需要完整显示的个性签名，用来验证不同状态栏高度不会改变页面间距。',
      fanCount: 12,
      workCount: 3,
      likeCount: 45,
      isFollowing: false,
      isSubscribed: false,
    );
    final gaps = <double>[];

    for (final safeTop in <double>[0, 48]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 700),
              padding: EdgeInsets.only(top: safeTop),
            ),
            child: Builder(
              builder: (context) => DefaultTabController(
                length: 3,
                child: Builder(
                  builder: (context) => Scaffold(
                    body: UserProfileScrollLayout(
                      controller: DefaultTabController.of(context),
                      isCurrentUser: true,
                      headerExtent: UserProfileHeader.extentFor(
                        context,
                        profile,
                        width: 400,
                      ),
                      onBack: () {},
                      onSearch: () {},
                      header: UserProfileHeader(
                        profile: profile,
                        isCurrentUser: true,
                        following: false,
                        onFollow: () {},
                        onMessage: () {},
                        onCharge: () {},
                        onEdit: () {},
                        showNavigation: false,
                      ),
                      children: const <Widget>[
                        SizedBox.expand(),
                        SizedBox.expand(),
                        SizedBox.expand(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardRect = tester.getRect(
        find.byKey(const ValueKey<String>('user_profile_card')),
      );
      final tabsRect = tester.getRect(
        find.byKey(const ValueKey<String>('user_profile_tabs')),
      );
      gaps.add(tabsRect.top - cardRect.bottom);
      expect(tester.takeException(), isNull);
    }

    expect(gaps[0], closeTo(8, .1));
    expect(gaps[1], closeTo(gaps[0], .1));
  });

  testWidgets('不同安全区下分类标题与作品间距保持八像素', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final group = UserProfileHighlightGroup(
      count: 1,
      posts: <PostSummary>[
        PostSummary.fromJson(<String, dynamic>{'id': 18, 'title': '点赞视频列表项'}),
      ],
    );
    final gaps = <double>[];

    for (final safeTop in <double>[0, 48]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 700),
              padding: EdgeInsets.only(top: safeTop),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: UserProfileHighlightSection(
                  userId: 88,
                  type: UserProfileVideoType.liked,
                  group: group,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final headerRect = tester.getRect(
        find.byKey(const ValueKey<String>('user_profile_highlight_header_1')),
      );
      final cardRect = tester.getRect(find.byType(UserProfilePostCard));
      gaps.add(cardRect.top - headerRect.bottom);
      expect(tester.takeException(), isNull);
    }

    expect(gaps[0], closeTo(8, .1));
    expect(gaps[1], closeTo(gaps[0], .1));
  });

  testWidgets('个人空间整体滚动后页签吸附在返回栏下方', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Builder(
            builder: (context) => Scaffold(
              body: UserProfileScrollLayout(
                controller: DefaultTabController.of(context),
                isCurrentUser: false,
                onBack: () {},
                onSearch: () {},
                header: const SizedBox(
                  key: ValueKey<String>('profile_scroll_header'),
                  height: 300,
                ),
                children: <Widget>[
                  ListView.builder(
                    key: const ValueKey<String>('profile_dynamic_list'),
                    itemCount: 30,
                    itemExtent: 60,
                    itemBuilder: (_, index) => Text('动态 $index'),
                  ),
                  ListView.builder(
                    itemCount: 30,
                    itemExtent: 60,
                    itemBuilder: (_, index) => Text('投稿 $index'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final header = find.byKey(const ValueKey<String>('profile_scroll_header'));
    expect(tester.getTopLeft(header).dy, 0);
    await tester.drag(
      find.byKey(const ValueKey<String>('profile_dynamic_list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(0));
    final tabBarRect = tester.getRect(find.byType(TabBar));
    final backIconRect = tester.getRect(
      find.byIcon(CupertinoIcons.chevron_back),
    );
    expect(tabBarRect.top, greaterThanOrEqualTo(backIconRect.bottom));
    expect(tabBarRect.top, lessThan(70));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile video more page keeps the legacy two-column card grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: UserProfileVideoPage(
          arguments: const UserProfileVideoArguments(
            userId: 7,
            type: UserProfileVideoType.collected,
          ),
          loader: (_, _) async => PagedResult<PostSummary>(
            page: 1,
            totalPages: 1,
            totalItems: 1,
            isLastPage: true,
            items: <PostSummary>[
              PostSummary.fromJson(<String, dynamic>{
                'id': 18,
                'title': '收藏视频列表项',
                'cover_images': <String>['/cover.jpg'],
                'views_num': 12,
                'collect_num': 3,
              }),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('收藏视频'), findsOneWidget);
    expect(find.text('收藏视频列表项'), findsOneWidget);
    expect(find.text('12  ·  3'), findsOneWidget);
    expect(find.text('没有更多了'), findsOneWidget);

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
    final delegate = grid.gridDelegate;
    expect(delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    expect(
      (delegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount,
      2,
    );
    expect(tester.takeException(), isNull);
  });
}
