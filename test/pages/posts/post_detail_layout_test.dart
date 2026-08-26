import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/posts/components/post_action_bar.dart';
import 'package:b_flutter/pages/posts/post_detail_page.dart';

void main() {
  test('blank legacy html does not reserve detail header spacing', () {
    expect(postHtmlHasVisibleContent('<p><br></p>'), isFalse);
    expect(postHtmlHasVisibleContent('<div>&nbsp; &#160;</div>'), isFalse);
    expect(postHtmlHasVisibleContent('<p>可见简介</p>'), isTrue);
    expect(postHtmlHasVisibleContent('<p><img src="cover.jpg"></p>'), isTrue);
  });

  group('post detail legacy layout routing', () {
    test('forum category keeps the forum document layout', () {
      final detail = PostDetail.fromJson(<String, dynamic>{
        'id': 83,
        'plate_one_id': 83,
        'type': 2,
      });

      expect(resolvePostDetailLayout(detail), PostDetailLayout.forum);
      expect(
        postDetailLayoutAllowsInnerRefresh(PostDetailLayout.forum),
        isFalse,
      );
    });

    test('forum video joins the pinned video and tab header', () {
      final video = PostDetail.fromJson(<String, dynamic>{
        'id': 84,
        'plate_one_id': 83,
        'type': 3,
        'cover_images': <String>['forum-video.jpg'],
        'play_video_url': <Map<String, dynamic>>[
          <String, dynamic>{'title': '线路1', 'url': 'video.mp4'},
        ],
      });
      final picture = PostDetail.fromJson(<String, dynamic>{
        'id': 85,
        'plate_one_id': 83,
        'type': 2,
        'cover_images': <String>['forum-picture.jpg'],
      });
      final lockedVideoWithoutLine = PostDetail.fromJson(<String, dynamic>{
        'id': 86,
        'plate_one_id': 83,
        'type': 3,
        'cover_images': <String>['locked-forum-video.jpg'],
        'price': 2,
        'is_buy': 1,
      });
      final lockedTextWithCover = PostDetail.fromJson(<String, dynamic>{
        'id': 87,
        'plate_one_id': 83,
        'type': 4,
        'cover_images': <String>['forum-text-cover.jpg'],
        'price': 2,
        'is_buy': 1,
      });

      expect(forumDetailHasPinnedVideo(video), isTrue);
      expect(forumDetailHasPinnedVideo(lockedVideoWithoutLine), isTrue);
      expect(forumDetailHasPinnedVideo(picture), isFalse);
      expect(forumDetailHasPinnedVideo(lockedTextWithCover), isFalse);
    });

    test('manga collection opens the collection overview', () {
      final detail = PostDetail.fromJson(<String, dynamic>{
        'id': 6,
        'plate_one_id': 6,
        'type': 5,
        'collection_type': 1,
        'horizontal_images': <String>['manga-wide.jpg'],
        'plate_two_obj': <String, dynamic>{'name': '日漫'},
      });

      expect(resolvePostDetailLayout(detail), PostDetailLayout.mangaCollection);
      expect(detail.horizontalCoverUrls, <String>['manga-wide.jpg']);
      expect(detail.secondaryCategoryName, '日漫');
    });

    test('manga chapter opens the dark reader', () {
      final detail = PostDetail.fromJson(<String, dynamic>{
        'id': 7,
        'plate_one_id': 6,
        'type': 5,
        'collection_type': 0,
      });

      expect(resolvePostDetailLayout(detail), PostDetailLayout.mangaReader);
    });

    test('other posts retain the standard detail layout', () {
      final detail = PostDetail.fromJson(<String, dynamic>{
        'id': 1,
        'plate_one_id': 9,
        'type': 1,
      });

      expect(resolvePostDetailLayout(detail), PostDetailLayout.standard);
      expect(
        postDetailLayoutAllowsInnerRefresh(PostDetailLayout.standard),
        isTrue,
      );
    });
  });

  testWidgets('post action bar keeps the legacy 50 high six-action layout', (
    tester,
  ) async {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 1,
      'like_num': 1,
      'collect_num': 2,
      'coin_num': 3,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostActionBar(
            detail: detail,
            isSubmitting: (_) => false,
            onLike: () {},
            onCollect: () {},
            onCoin: () {},
            onLine: () {},
            onFeedback: () {},
            onShare: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PostActionBar)).height, 50);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('播放线路'), findsOneWidget);
    expect(find.text('反馈'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('post_action_feedback_legacy_line_icon'),
      ),
      findsOneWidget,
    );
    expect(tester.widget<Text>(find.text('反馈')).style?.fontSize, 12);
    expect(tester.takeException(), isNull);
  });
}
