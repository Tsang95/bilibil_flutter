import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/mine/look_history_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('history preserves the legacy filter and creator post card', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: LookHistoryPage(
          loadCategories: () async => <HomeCategory>[
            const HomeCategory(
              id: 6,
              parentId: 0,
              name: '短视频',
              backgroundUrl: '',
              itemCount: 0,
              styleType: 0,
              showModel: 0,
              children: <HomeCategory>[],
            ),
          ],
          loadPage: (_, _, _) async => PagedResult<PostSummary>(
            page: 1,
            totalPages: 1,
            totalItems: 1,
            isLastPage: true,
            items: <PostSummary>[
              PostSummary.fromJson(<String, dynamic>{
                'id': 5,
                'title': '历史视频',
                'cover_images': <String>[''],
                'member_obj': <String, dynamic>{'nickname': '作者'},
                'plate_two_obj': <String, dynamic>{'name': '短视频'},
              }),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('历史记录'), findsOneWidget);
    expect(find.text('当前板块：'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('历史视频'), findsOneWidget);
    expect(find.text('#短视频'), findsOneWidget);
    expect(find.text('购买：0'), findsOneWidget);
    expect(find.text('浏览：0'), findsOneWidget);
    expect(find.text('收藏：0'), findsOneWidget);
  });

  testWidgets('first category tap waits for the initial category request', (
    tester,
  ) async {
    final categories = Completer<List<HomeCategory>>();
    await tester.pumpWidget(
      GetMaterialApp(
        home: LookHistoryPage(
          loadCategories: () => categories.future,
          loadPage: (_, _, _) async => const PagedResult<PostSummary>(
            page: 1,
            totalPages: 1,
            totalItems: 0,
            isLastPage: true,
            items: <PostSummary>[],
          ),
        ),
      ),
    );

    await tester.tap(find.text('全部'));
    await tester.pump();
    categories.complete(<HomeCategory>[
      const HomeCategory(
        id: 6,
        parentId: 0,
        name: '短视频',
        backgroundUrl: '',
        itemCount: 0,
        styleType: 0,
        showModel: 0,
        children: <HomeCategory>[],
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('短视频'), findsOneWidget);
  });
}
