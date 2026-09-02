import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/pages/creator/creator_work_page.dart';

void main() {
  testWidgets('empty creator category invokes its prerequisite action', (
    tester,
  ) async {
    var prerequisiteTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreatorSelectRow<String>(
            name: '分类',
            placeholder: '分类名称',
            items: const <String>[],
            selected: null,
            label: (item) => item,
            onSelected: (_) {},
            onEmptyTap: () => prerequisiteTaps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('分类'));

    expect(prerequisiteTaps, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('creator option sheet scrolls on a short screen', (tester) async {
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCreatorOptionSheet(
                context,
                title: '话题',
                labels: List<String>.generate(30, (index) => '话题$index'),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('creator_option_sheet_list')),
      findsOneWidget,
    );
    expect(find.text('话题0'), findsOneWidget);
    expect(find.text('话题29'), findsNothing);

    await tester.fling(
      find.byKey(const ValueKey<String>('creator_option_sheet_list')),
      const Offset(0, -1200),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('话题29'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
