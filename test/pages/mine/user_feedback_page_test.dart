import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/pages/mine/user_feedback_page.dart';

void main() {
  testWidgets('user feedback preserves the legacy 500-character form', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UserFeedbackPage()));

    expect(find.text('用户建议'), findsOneWidget);
    expect(find.text('请提供以下信息以便更好的处理您的建议：'), findsOneWidget);
    expect(find.text('提交'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
  });
}
