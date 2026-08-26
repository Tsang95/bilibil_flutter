import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
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
