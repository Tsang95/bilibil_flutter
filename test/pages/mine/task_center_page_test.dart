import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:b_flutter/pages/mine/task_center_page.dart';

void main() {
  setUp(() => Get.testMode = true);

  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });

  testWidgets('task centre keeps the legacy navigation title while loading', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: TaskCenterPage()));

    expect(find.text('任务中心'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
