import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/movie_models.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/movie/components/movie_actor_work_card.dart';
import 'package:b_flutter/pages/movie/components/movie_post_card.dart';

void main() {
  testWidgets('movie post card keeps legacy 100 high cover and metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 172,
            height: 140,
            child: MoviePostCard(post: _post),
          ),
        ),
      ),
    );

    expect(find.text('影视标题'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);

    final cover = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .firstWhere((box) => box.height == 100);
    expect(cover.height, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actor work card keeps legacy 140 by 210 portrait layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MovieActorWorkCard(
              work: MovieActorWork(
                id: 9,
                coverUrls: <String>[],
                title: '作品',
                isVipOnly: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MovieActorWorkCard)),
      const Size(140, 210),
    );
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('作品'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

const _post = PostSummary(
  id: 1,
  title: '影视标题',
  description: '',
  type: 2,
  price: 0,
  coverUrls: <String>[],
  horizontalCoverUrls: <String>[],
  durationSeconds: 90,
  viewCount: 120,
  collectCount: 8,
  likeCount: 0,
  salesCount: 0,
  isVipOnly: true,
  isPurchased: false,
  unlockType: 2,
  isOriginal: false,
  label: '',
  authorNickname: '',
  categoryName: '',
  createdAt: null,
  primaryCategoryId: 19,
);
