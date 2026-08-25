import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/creation_topic.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/creator/creation_center_page.dart';
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

  testWidgets('creation centre restores inspiration and academy sections', (
    tester,
  ) async {
    final groups = <CreationTopicGroup>[
      const CreationTopicGroup(
        id: 1,
        name: '热门',
        topics: <CreationTopic>[
          CreationTopic(
            id: 8,
            title: '夏日投稿',
            description: '',
            viewCount: 999,
            commentCount: 0,
            lastTime: '',
            labelId: 5,
          ),
        ],
      ),
    ];
    final schoolPosts = <PostSummary>[
      PostSummary.fromJson(<String, dynamic>{
        'id': 9,
        'title': '创作入门课程',
        'cover_images': <String>[],
      }),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: CreationCenterPage(
          topicsLoader: ({bool forceRefresh = false}) async => groups,
          schoolLoader: ({bool forceRefresh = false}) async => schoolPosts,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('创作中心'), findsOneWidget);
    expect(find.text('创作灵感'), findsOneWidget);
    expect(find.text('热门'), findsOneWidget);
    expect(find.text('夏日投稿'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
    expect(find.text('投稿'), findsOneWidget);
    expect(find.text('创作学院'), findsOneWidget);
    expect(find.text('创作入门课程'), findsOneWidget);

    await tester.tap(find.text('投稿'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('您不是UP主会员'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认'), findsOneWidget);
  });
}
