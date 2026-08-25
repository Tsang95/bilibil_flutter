import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/models/creator_models.dart';
import 'package:b_flutter/pages/creator/creator_center_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() {
    Get.reset();
  });

  testWidgets('creator centre restores notices, work counts and income table', (
    tester,
  ) async {
    var publishTapped = false;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CreatorCenterPage(
          onPublish: () => publishTapped = true,
          loader: ({bool forceRefresh = false}) async => const CreatorDashboard(
            allCount: 12,
            reviewingCount: 3,
            collectionCount: 45,
            incomes: <CreatorIncome>[
              CreatorIncome(
                id: 1,
                goldAmount: 8,
                postTitle: '收益帖子',
                createdAt: '2026-08-25',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('创作者中心'), findsOneWidget);
    expect(find.text('发布作品'), findsOneWidget);
    expect(find.text('创作必看'), findsOneWidget);
    expect(find.textContaining('严禁发布幼女'), findsOneWidget);
    expect(find.text('我的作品'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('展示最近7天的收益'), findsOneWidget);
    expect(find.text('收益帖子'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('creator_publish_button')),
    );
    expect(publishTapped, isTrue);
  });
}
