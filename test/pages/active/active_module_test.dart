import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/active/active_feed_controller.dart';
import 'package:b_flutter/pages/active/components/active_post_card.dart';

void main() {
  PostSummary post(int id, {List<String> covers = const <String>[]}) =>
      PostSummary(
        id: id,
        title: '动态标题$id',
        description: '',
        type: 1,
        price: 0,
        coverUrls: covers,
        horizontalCoverUrls: const <String>[],
        durationSeconds: 0,
        viewCount: 12,
        collectCount: 34,
        likeCount: 56,
        salesCount: 0,
        isVipOnly: false,
        isPurchased: false,
        unlockType: 0,
        isOriginal: false,
        label: '',
        authorNickname: '作者$id',
        categoryName: '',
        createdAt: DateTime.now(),
        primaryCategoryId: 0,
        isOnline: true,
      );

  test('全部动态按 type=0 分页并去除重复帖子', () async {
    final requests = <({int page, int type, bool forceRefresh})>[];
    final controller = ActiveFeedController(
      type: 0,
      loader: ({required page, required type, required forceRefresh}) async {
        requests.add((page: page, type: type, forceRefresh: forceRefresh));
        return page == 1
            ? pageResult(post(1), second: post(2), number: 1, totalPages: 2)
            : pageResult(post(2), second: post(3), number: 2, totalPages: 2);
      },
    );

    await controller.loadInitial();
    await controller.loadMore();

    expect(requests, <({int page, int type, bool forceRefresh})>[
      (page: 1, type: 0, forceRefresh: false),
      (page: 2, type: 0, forceRefresh: false),
    ]);
    expect(controller.items.map((item) => item.id), <int>[1, 2, 3]);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });

  test('视频动态刷新按 type=1 请求并强制刷新缓存', () async {
    late ({int page, int type, bool forceRefresh}) request;
    final controller = ActiveFeedController(
      type: 1,
      loader: ({required page, required type, required forceRefresh}) async {
        request = (page: page, type: type, forceRefresh: forceRefresh);
        return pageResult(post(8), number: 1, totalPages: 1);
      },
    );

    await controller.refresh();

    expect(request, (page: 1, type: 1, forceRefresh: true));
    expect(controller.items.single.id, 8);
    controller.dispose();
  });

  testWidgets('动态卡片保留单图 200 高和最多九张三列图片', (tester) async {
    final covers = List<String>.generate(10, (index) => 'cover-$index');
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ActivePostCard(post: post(1, covers: const <String>['cover'])),
                ActivePostCard(post: post(2, covers: covers)),
              ],
            ),
          ),
        ),
      ),
    );

    final singleCover = find.byKey(
      const ValueKey<String>('active_single_cover_1'),
    );
    expect(singleCover, findsOneWidget);
    expect(tester.getSize(singleCover).height, 200);
    expect(
      find.byKey(const ValueKey<String>('active_cover_grid_2')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<GridView>(
            find.byKey(const ValueKey<String>('active_cover_grid_2')),
          )
          .primary,
      isFalse,
    );
    for (var index = 0; index < 9; index++) {
      expect(
        find.byKey(ValueKey<String>('active_cover_2_$index')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('active_cover_2_9')),
      findsNothing,
    );
    expect(find.text('打赏'), findsNWidgets(2));
    expect(find.text('分享'), findsNWidgets(2));
  });
}

PagedResult<PostSummary> pageResult(
  PostSummary first, {
  PostSummary? second,
  required int number,
  required int totalPages,
}) =>
    PagedResult<PostSummary>(
      page: number,
      totalPages: totalPages,
      totalItems: second == null ? 1 : 2,
      isLastPage: number >= totalPages,
      items: <PostSummary>[first, if (second != null) second],
    );
