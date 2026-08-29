import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/mine/collect_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('collection reuses the legacy filtered creator-post layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: CollectPage(
          loadCategories: () async => const <HomeCategory>[],
          loadPage: (boardId, sort, page) async => PagedResult<PostSummary>(
            page: 1,
            totalPages: 1,
            totalItems: 1,
            isLastPage: true,
            items: <PostSummary>[
              PostSummary.fromJson(<String, dynamic>{
                'id': 2,
                'title': '收藏视频',
                'cover_images': <String>[''],
              }),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('我的收藏'), findsOneWidget);
    expect(find.text('当前板块：'), findsOneWidget);
    expect(find.text('收藏视频'), findsOneWidget);
  });
}
