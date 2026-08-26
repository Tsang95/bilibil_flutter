import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/topics/components/topic_post_card.dart';
import 'package:b_flutter/pages/topics/topic_posts_controller.dart';
import 'package:b_flutter/utils/legacy_display_format.dart';

void main() {
  PostSummary post(
    int id, {
    List<String> covers = const <String>[],
    List<String> horizontalCovers = const <String>[],
    int primaryCategoryId = 1,
  }) => PostSummary(
    id: id,
    title: '话题帖子',
    description: '',
    type: 1,
    price: 0,
    coverUrls: covers,
    horizontalCoverUrls: horizontalCovers,
    durationSeconds: 65,
    viewCount: 12,
    collectCount: 0,
    likeCount: 3,
    salesCount: 0,
    isVipOnly: false,
    isPurchased: false,
    unlockType: 0,
    isOriginal: false,
    label: '',
    authorNickname: '作者',
    categoryName: '',
    createdAt: DateTime.now(),
    primaryCategoryId: primaryCategoryId,
  );

  testWidgets('topic post card preserves legacy content bands', (tester) async {
    final item = post(1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TopicPostCard(post: item)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('作者'), findsOneWidget);
    expect(find.text('话题帖子'), findsOneWidget);
    expect(find.text('00:01:05'), findsOneWidget);
    expect(find.text('12 观看'), findsOneWidget);
    expect(find.text('转发'), findsOneWidget);
    expect(find.text('评论'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('话题卡片始终使用旧版普通封面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicPostCard(
            post: post(
              6,
              covers: const <String>['normal-cover'],
              horizontalCovers: const <String>['horizontal-cover'],
              primaryCategoryId: 6,
            ),
          ),
        ),
      ),
    );

    final cover = tester.widget<LegacyNetworkImage>(
      find.byKey(const ValueKey<String>('topic_post_cover_6')),
    );
    expect(cover.url, 'normal-cover');
  });

  test('话题分页传递 topicId、去重并在刷新时强制请求', () async {
    final requests = <({int topicId, int page, bool forceRefresh})>[];
    var refreshCount = 0;
    final controller = TopicPostsController(
      42,
      loader: ({required topicId, required page, required forceRefresh}) async {
        requests.add((
          topicId: topicId,
          page: page,
          forceRefresh: forceRefresh,
        ));
        if (forceRefresh) {
          refreshCount += 1;
          return pageResult(post(9), number: 1, totalPages: 1);
        }
        return page == 1
            ? pageResult(post(1), second: post(2), number: 1, totalPages: 2)
            : pageResult(post(2), second: post(3), number: 2, totalPages: 2);
      },
    );

    await controller.loadInitial();
    await controller.loadMore();
    await controller.refresh();

    expect(requests, <({int topicId, int page, bool forceRefresh})>[
      (topicId: 42, page: 1, forceRefresh: false),
      (topicId: 42, page: 2, forceRefresh: false),
      (topicId: 42, page: 1, forceRefresh: true),
    ]);
    expect(refreshCount, 1);
    expect(controller.items.map((item) => item.id), <int>[9]);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });

  test('旧版话题数量和时长格式保持不变', () {
    expect(formatLegacyCompactCount(1000), '1000');
    expect(formatLegacyCompactCount(1500), '1.5 k');
    expect(formatLegacyCompactCount(12000), '1.2 w');
    expect(formatLegacyCompactCount(1000001), '100.0 百万');
    expect(formatLegacyDuration(65), '00:01:05');
    expect(formatLegacyDuration(3661), '01:01:01');
    final now = DateTime(2026, 8, 26, 12);
    expect(
      formatLegacyRelativeTime(
        now.subtract(const Duration(minutes: 4)),
        now: now,
      ),
      '刚刚',
    );
    expect(
      formatLegacyRelativeTime(
        now.subtract(const Duration(minutes: 15)),
        now: now,
      ),
      '15分钟之前',
    );
    expect(
      formatLegacyRelativeTime(now.subtract(const Duration(days: 7)), now: now),
      '1周前',
    );
    expect(
      formatLegacyRelativeTime(DateTime(2026, 7, 1), now: now),
      '2026-07-01',
    );
  });
}

PagedResult<PostSummary> pageResult(
  PostSummary first, {
  PostSummary? second,
  required int number,
  required int totalPages,
}) => PagedResult<PostSummary>(
  page: number,
  totalPages: totalPages,
  totalItems: second == null ? 1 : 2,
  isLastPage: number >= totalPages,
  items: <PostSummary>[first, if (second != null) second],
);
