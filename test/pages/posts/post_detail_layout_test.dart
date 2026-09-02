import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/posts/components/post_action_bar.dart';
import 'package:b_flutter/pages/posts/post_detail_page.dart';
import 'package:b_flutter/routes/post_detail_route_arguments.dart';

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

  test('post summary metadata selects its corresponding loading skeleton', () {
    expect(
      PostDetailRouteArguments.fromMetadata(
        type: 1,
        collectionType: 0,
        primaryCategoryId: 9,
      ).loadingLayout,
      PostDetailLoadingLayout.immersiveVideo,
    );
    expect(
      PostDetailRouteArguments.fromMetadata(
        type: 2,
        collectionType: 0,
        primaryCategoryId: 83,
      ).loadingLayout,
      PostDetailLoadingLayout.forum,
    );
    expect(
      PostDetailRouteArguments.fromMetadata(
        type: 5,
        collectionType: 1,
        primaryCategoryId: 6,
      ).loadingLayout,
      PostDetailLoadingLayout.mangaCollection,
    );
    expect(
      PostDetailRouteArguments.fromMetadata(
        type: 5,
        collectionType: 0,
        primaryCategoryId: 6,
      ).loadingLayout,
      PostDetailLoadingLayout.mangaReader,
    );
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
      find.byKey(const ValueKey<String>('post_action_feedback_icon')),
      findsOneWidget,
    );
    expect(tester.widget<Text>(find.text('反馈')).style?.fontSize, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post detail initial loading uses the internal layout skeleton', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PostDetailLoadingSkeleton())),
    );

    expect(
      find.byKey(const ValueKey<String>('post_detail_loading_skeleton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_media')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_author')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_actions')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('post_detail_skeleton_media'),
            ),
          )
          .height,
      206,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picture post loading mirrors the content-first layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const arguments = PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.standard,
      showContentPlaceholder: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PostDetailLoadingSkeleton(routeArguments: arguments),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_standard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_media')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('immersive video loading does not flash a light app bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const arguments = PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.immersiveVideo,
      showPlayerPlaceholder: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PostDetailLoadingScaffold(routeArguments: arguments),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('immersive_video_loading_scaffold'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_media')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('forum loading keeps content before its pinned detail header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const arguments = PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.forum,
      showContentPlaceholder: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PostDetailLoadingSkeleton(routeArguments: arguments),
        ),
      ),
    );

    final content = find.byKey(
      const ValueKey<String>('post_detail_skeleton_forum_content'),
    );
    final tabs = find.byKey(
      const ValueKey<String>('post_detail_skeleton_tabs'),
    );
    expect(content, findsOneWidget);
    expect(tabs, findsOneWidget);
    expect(tester.getTopLeft(content).dy, lessThan(tester.getTopLeft(tabs).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('manga collection loading mirrors cover and chapter layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const arguments = PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.mangaCollection,
      horizontalCover: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PostDetailLoadingScaffold(routeArguments: arguments),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('manga_collection_loading_scaffold'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('post_detail_skeleton_manga_cover'),
            ),
          )
          .height,
      240,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('manga reader loading uses the dark reading skeleton', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const arguments = PostDetailRouteArguments(
      loadingLayout: PostDetailLoadingLayout.mangaReader,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PostDetailLoadingScaffold(routeArguments: arguments),
      ),
    );

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey<String>('manga_reader_loading_scaffold')),
    );
    expect(scaffold.backgroundColor, const Color(0xff1E202C));
    expect(
      find.byKey(const ValueKey<String>('post_detail_skeleton_manga_reader')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
