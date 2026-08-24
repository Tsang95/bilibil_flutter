import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/topics/components/topic_post_card.dart';

void main() {
  testWidgets('topic post card preserves legacy content bands', (tester) async {
    final post = PostSummary(
      id: 1,
      title: '话题帖子',
      description: '',
      type: 1,
      price: 0,
      coverUrls: const <String>[],
      horizontalCoverUrls: const <String>[],
      durationSeconds: 65,
      viewCount: 12,
      collectCount: 0,
      likeCount: 3,
      salesCount: 0,
      isVipOnly: false,
      isPurchased: false,
      unlockType: 0,
      isOriginal: false,
      label: '',
      authorNickname: '作者',
      categoryName: '',
      createdAt: DateTime.now(),
      primaryCategoryId: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TopicPostCard(post: post)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('作者'), findsOneWidget);
    expect(find.text('话题帖子'), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('12 观看'), findsOneWidget);
    expect(find.text('转发'), findsOneWidget);
    expect(find.text('评论'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
