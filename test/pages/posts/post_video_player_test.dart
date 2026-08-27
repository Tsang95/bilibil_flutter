import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/common_barrage.dart';
import 'package:b_flutter/pages/posts/components/post_common_barrage_list.dart';
import 'package:b_flutter/pages/posts/components/post_video_player.dart';

void main() {
  test('shows buffering feedback only for an initialized buffering video', () {
    expect(
      shouldShowPostVideoBufferingIndicator(
        isInitialized: true,
        isBuffering: true,
      ),
      isTrue,
    );
    expect(
      shouldShowPostVideoBufferingIndicator(
        isInitialized: true,
        isBuffering: false,
      ),
      isFalse,
    );
    expect(
      shouldShowPostVideoBufferingIndicator(
        isInitialized: false,
        isBuffering: true,
      ),
      isFalse,
    );
  });

  test('rearms controls auto-hide after seeking or buffering resumes', () {
    expect(
      shouldRearmPostVideoControlsAutoHide(
        wasPlaying: false,
        isPlaying: true,
        wasBuffering: false,
        isBuffering: false,
      ),
      isTrue,
    );
    expect(
      shouldRearmPostVideoControlsAutoHide(
        wasPlaying: true,
        isPlaying: true,
        wasBuffering: true,
        isBuffering: false,
      ),
      isTrue,
    );
    expect(
      shouldRearmPostVideoControlsAutoHide(
        wasPlaying: false,
        isPlaying: false,
        wasBuffering: true,
        isBuffering: true,
      ),
      isFalse,
    );
  });

  test('long press temporarily uses 2x and restores the selected speed', () {
    final state = PostVideoLongPressSpeedState();

    expect(
      state.begin(isInitialized: true, isPlaying: false, currentSpeed: 1.25),
      isFalse,
    );
    expect(
      state.begin(isInitialized: true, isPlaying: true, currentSpeed: 1.25),
      isTrue,
    );
    expect(state.isActive, isTrue);
    expect(postVideoLongPressPlaybackSpeed, 2);
    expect(
      state.begin(isInitialized: true, isPlaying: true, currentSpeed: 1),
      isFalse,
    );
    expect(state.end(), 1.25);
    expect(state.isActive, isFalse);
    expect(state.end(), isNull);
  });

  test('resumes only when playback was active before an interruption', () {
    final state = PostVideoPlaybackInterruptionState();

    expect(
      state.begin(
        PostVideoPlaybackInterruption.navigation,
        isPlaying: true,
        isInitializing: false,
      ),
      isTrue,
    );
    expect(state.end(PostVideoPlaybackInterruption.navigation), isTrue);

    expect(
      state.begin(
        PostVideoPlaybackInterruption.navigation,
        isPlaying: false,
        isInitializing: false,
      ),
      isFalse,
    );
    expect(state.end(PostVideoPlaybackInterruption.navigation), isFalse);
  });

  test('waits for every overlapping playback interruption to end', () {
    final state = PostVideoPlaybackInterruptionState();

    expect(
      state.begin(
        PostVideoPlaybackInterruption.navigation,
        isPlaying: true,
        isInitializing: false,
      ),
      isTrue,
    );
    expect(
      state.begin(
        PostVideoPlaybackInterruption.application,
        isPlaying: false,
        isInitializing: false,
      ),
      isFalse,
    );
    expect(state.end(PostVideoPlaybackInterruption.navigation), isFalse);
    expect(state.end(PostVideoPlaybackInterruption.application), isTrue);
  });

  test('waits for nested page navigations before resuming playback', () {
    final state = PostVideoPlaybackInterruptionState();

    expect(
      state.begin(
        PostVideoPlaybackInterruption.navigation,
        isPlaying: true,
        isInitializing: false,
      ),
      isTrue,
    );
    expect(
      state.begin(
        PostVideoPlaybackInterruption.navigation,
        isPlaying: false,
        isInitializing: false,
      ),
      isFalse,
    );
    expect(state.end(PostVideoPlaybackInterruption.navigation), isFalse);
    expect(state.end(PostVideoPlaybackInterruption.navigation), isTrue);
  });

  test('removes the cover after an unlocked video player is ready', () {
    expect(
      shouldShowPostVideoCover(
        isRegistrationLocked: false,
        requiresCoinUnlock: false,
        requiresVipUnlock: false,
        hasVideo: true,
        isLoading: false,
        hasError: false,
        hasPlayerController: true,
      ),
      isFalse,
    );

    expect(
      shouldShowPostVideoCover(
        isRegistrationLocked: false,
        requiresCoinUnlock: false,
        requiresVipUnlock: false,
        hasVideo: true,
        isLoading: true,
        hasError: false,
        hasPlayerController: true,
      ),
      isTrue,
    );
    expect(
      shouldShowPostVideoCover(
        isRegistrationLocked: false,
        requiresCoinUnlock: true,
        requiresVipUnlock: false,
        hasVideo: true,
        isLoading: false,
        hasError: false,
        hasPlayerController: true,
      ),
      isTrue,
    );
  });

  testWidgets('shows coin requirement without initializing playback', (
    tester,
  ) async {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 1,
      'is_buy': 1,
      'price': 5,
      'sales_num': 20,
      'play_video_url': <Object?>[
        <String, dynamic>{
          'title': '线路一',
          'url': 'https://video.example.test/a.mp4',
        },
      ],
    });

    await tester.pumpWidget(_TestApp(detail: detail));

    expect(find.text('当前内容需付费5金币购买，点我立即购买！'), findsOneWidget);
    expect(find.text('已购买人数：20'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows VIP requirement without initializing playback', (
    tester,
  ) async {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 2,
      'is_buy': 2,
      'play_video_url': <Object?>[
        <String, dynamic>{
          'title': '线路一',
          'url': 'https://video.example.test/a.mp4',
        },
      ],
    });

    await tester.pumpWidget(_TestApp(detail: detail));

    expect(find.text('当前内容需开通VIP，点我立即购买！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked video sends coin and VIP requests to their callbacks', (
    tester,
  ) async {
    var coinRequests = 0;
    var vipRequests = 0;
    final coinDetail = PostDetail.fromJson(<String, dynamic>{
      'id': 20,
      'is_buy': 1,
      'price': 8,
      'play_video_url': <Object?>[
        <String, dynamic>{'url': 'https://video.example.test/coin.mp4'},
      ],
    });
    final vipDetail = PostDetail.fromJson(<String, dynamic>{
      'id': 21,
      'is_buy': 2,
      'play_video_url': <Object?>[
        <String, dynamic>{'url': 'https://video.example.test/vip.mp4'},
      ],
    });

    await tester.pumpWidget(
      _TestApp(detail: coinDetail, onCoinUnlockRequired: () => coinRequests++),
    );
    await tester.tap(find.text('当前内容需付费8金币购买，点我立即购买！'));
    expect(coinRequests, 1);

    await tester.pumpWidget(
      _TestApp(detail: vipDetail, onVipUnlockRequired: () => vipRequests++),
    );
    await tester.tap(find.text('当前内容需开通VIP，点我立即购买！'));
    expect(vipRequests, 1);
  });

  testWidgets('detaches the external player controller on disposal', (
    tester,
  ) async {
    final controller = PostVideoPlayerController();
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 3,
      'is_buy': 2,
      'play_video_url': <Object?>[
        <String, dynamic>{
          'title': '线路一',
          'url': 'https://video.example.test/a.mp4',
        },
      ],
    });

    await tester.pumpWidget(_TestApp(detail: detail, controller: controller));
    expect(controller.isAttached, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.isAttached, isFalse);
  });

  testWidgets('guest-only content asks for login without starting playback', (
    tester,
  ) async {
    var loginRequests = 0;
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 4,
      'jump_register': 1,
      'price': 0,
      'play_video_url': <Object?>[
        <String, dynamic>{
          'title': '线路一',
          'url': 'https://video.example.test/a.mp4',
        },
      ],
    });

    await tester.pumpWidget(
      _TestApp(detail: detail, onLoginRequired: () => loginRequests++),
    );
    await tester.tap(find.text('登录后观看'));

    expect(loginRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('common barrage list closes from its toggle area and selects', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _CommonBarrageListHarness())),
    );
    final toggle = find.text('展开弹幕');
    final toggleCenter = tester.getCenter(toggle);

    await tester.tap(toggle);
    await tester.pump();
    expect(find.text('测试弹幕'), findsOneWidget);

    await tester.tapAt(toggleCenter);
    await tester.pump();
    expect(find.text('测试弹幕'), findsNothing);

    await tester.tap(toggle);
    await tester.pump();
    await tester.tap(find.text('测试弹幕'));
    await tester.pump();
    expect(find.text('已选择：测试弹幕'), findsOneWidget);
  });
}

class _CommonBarrageListHarness extends StatefulWidget {
  const _CommonBarrageListHarness();

  @override
  State<_CommonBarrageListHarness> createState() =>
      _CommonBarrageListHarnessState();
}

class _CommonBarrageListHarnessState extends State<_CommonBarrageListHarness> {
  final GlobalKey _anchorKey = GlobalKey();
  String _selected = '';

  Future<void> _showList() async {
    final anchor = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchor == null) return;
    final selected = await showPostCommonBarrageList(
      context: context,
      anchor: anchor,
      barrages: const <CommonBarrage>[CommonBarrage(id: 1, content: '测试弹幕')],
    );
    if (selected != null && mounted) setState(() => _selected = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton(
            key: _anchorKey,
            onPressed: _showList,
            child: const Text('展开弹幕'),
          ),
          Text('已选择：$_selected'),
        ],
      ),
    );
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.detail,
    this.controller,
    this.onLoginRequired,
    this.onCoinUnlockRequired,
    this.onVipUnlockRequired,
  });

  final PostDetail detail;
  final PostVideoPlayerController? controller;
  final VoidCallback? onLoginRequired;
  final VoidCallback? onCoinUnlockRequired;
  final VoidCallback? onVipUnlockRequired;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 375,
            child: AspectRatio(
              aspectRatio: 375 / 206,
              child: PostVideoPlayer(
                detail: detail,
                controller: controller,
                onLoginRequired: onLoginRequired,
                onCoinUnlockRequired: onCoinUnlockRequired,
                onVipUnlockRequired: onVipUnlockRequired,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
