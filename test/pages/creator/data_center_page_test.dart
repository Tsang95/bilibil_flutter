import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/creator_data_center_models.dart';
import 'package:b_flutter/pages/creator/data_center_page.dart';

void main() {
  testWidgets('data center restores three tabs and overview metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorDataCenterPage(
          reportLoader: ({required type, forceRefresh = false}) async =>
              _report,
          chartLoader: ({required kind, forceRefresh = false}) async =>
              const <CreatorChartPoint>[
            CreatorChartPoint(date: '08-24', value: 8),
            CreatorChartPoint(date: '08-25', value: 12),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('数据中心'), findsOneWidget);
    expect(find.text('数据概览'), findsOneWidget);
    expect(find.text('创作收益'), findsOneWidget);
    expect(find.text('粉丝分析'), findsOneWidget);
    expect(find.text('播放量'), findsOneWidget);
    expect(find.text('空间访客'), findsOneWidget);
    expect(find.text('净增粉丝'), findsOneWidget);
    expect(find.text('点赞'), findsOneWidget);
    expect(find.text('弹幕'), findsOneWidget);
  });

  testWidgets('fans tab restores the three legacy fan cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CreatorDataCenterPage(
          reportLoader: ({required type, forceRefresh = false}) async =>
              _report,
          chartLoader: ({required kind, forceRefresh = false}) async =>
              const <CreatorChartPoint>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('粉丝分析'));
    await tester.pumpAndSettle();

    expect(find.text('粉丝变化'), findsOneWidget);
    expect(find.text('新增关注'), findsOneWidget);
    expect(find.text('取消关注'), findsOneWidget);
    expect(find.text('粉丝总数'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
  });
}

const _report = CreatorDataReport(
  totalPlayCount: 120,
  visitorCount: 30,
  totalFanCount: 40,
  fanIncreaseCount: 8,
  newFanCount: 10,
  lostFanCount: 2,
  praiseCount: 18,
  collectCount: 16,
  coinCount: 12,
  commentCount: 9,
  barrageCount: 7,
  goldCount: 6,
);
