import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/posts/components/post_more_action_sheet.dart';

void main() {
  testWidgets('more action sheet restores the legacy four actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostMoreActionSheet(
            postId: 7,
            initialDetail: PostDetail.fromJson(<String, dynamic>{
              'id': 7,
              'is_collect': 0,
            }),
          ),
        ),
      ),
    );

    expect(find.text('分享'), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    expect(find.text('举报'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collected post keeps the legacy cancel-follow wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostMoreActionSheet(
            postId: 8,
            initialDetail: PostDetail.fromJson(<String, dynamic>{
              'id': 8,
              'is_collect': 1,
            }),
          ),
        ),
      ),
    );

    expect(find.text('取消关注'), findsOneWidget);
  });
}
