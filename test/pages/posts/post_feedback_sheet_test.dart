import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/posts/components/post_feedback_sheet.dart';

void main() {
  testWidgets('feedback reasons have a Material ink surface', (tester) async {
    final reasons = <PostFeedbackReason>[
      const PostFeedbackReason(id: 1, content: '视频无法播放'),
      const PostFeedbackReason(id: 2, content: '内容与标题不符'),
      const PostFeedbackReason(id: 3, content: '其他问题'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostFeedbackSheet(reasons: reasons, onSubmit: (_, _) async {}),
        ),
      ),
    );

    expect(find.byType(Material), findsWidgets);
    final closeCenter = tester.getCenter(find.byIcon(Icons.close_rounded));
    final sheetWidth = tester.getSize(find.byType(PostFeedbackSheet)).width;
    expect(closeCenter.dx, greaterThan(sheetWidth * 0.85));
    expect(tester.takeException(), isNull);
  });
}
