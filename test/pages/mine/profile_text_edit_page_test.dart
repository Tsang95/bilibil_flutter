import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/pages/mine/profile_text_edit_page.dart';

void main() {
  testWidgets(
    'profile text editor preserves the legacy text area and counter',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileTextEditPage(
            arguments: ProfileTextEditArguments(
              title: '昵称',
              maxLength: 16,
              initialValue: '旧昵称',
            ),
          ),
        ),
      );

      expect(find.text('昵称'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('3/16'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 16);
    },
  );
}
