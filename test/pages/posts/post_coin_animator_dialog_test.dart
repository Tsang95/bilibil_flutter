import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/pages/posts/components/post_coin_animator_dialog.dart';

void main() {
  testWidgets('a balance equal to the selected coin count can be submitted', (
    tester,
  ) async {
    var submittedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PostCoinAnimatorDialog(
                  initialBalance: 1,
                  onTip: (count) async => submittedCount = count,
                ),
              ),
              child: const Text('打开一枚投币'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开一枚投币'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('post_coin_person')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(submittedCount, 1);
    expect(
      find.byKey(const ValueKey<String>('post_coin_animator_dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a coin then tapping 22娘 submits and closes', (
    tester,
  ) async {
    var submittedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PostCoinAnimatorDialog(
                    initialBalance: 3,
                    onTip: (count) async => submittedCount = count,
                  ),
                ),
                child: const Text('打开投币'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开投币'));
    await tester.pumpAndSettle();
    expect(find.text('点击22娘投硬币'), findsOneWidget);
    expect(find.text('硬币余额：3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('post_coin_option_2')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey<String>('post_coin_person')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(submittedCount, 2);
    expect(
      find.byKey(const ValueKey<String>('post_coin_animator_dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
