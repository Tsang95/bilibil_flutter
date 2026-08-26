import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:chewie/chewie.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/adapter/fanjiao_danmu_adapter.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/danmu_controller.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/danmu_model.dart';
import 'package:fanjiao_danmu/fanjiao_danmu/danmu_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/post_barrage.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/toast.dart';
import 'package:b_flutter/utils/video_url_resolver.dart';

@visibleForTesting
bool shouldShowPostVideoCover({
  required bool isRegistrationLocked,
  required bool requiresCoinUnlock,
  required bool requiresVipUnlock,
  required bool hasVideo,
  required bool isLoading,
  required bool hasError,
  required bool hasPlayerController,
}) {
  return isRegistrationLocked ||
      requiresCoinUnlock ||
      requiresVipUnlock ||
      !hasVideo ||
      isLoading ||
      hasError ||
      !hasPlayerController;
}

class PostVideoPlayerController {
  _PostVideoPlayerState? _state;

  Duration get position =>
      _state?._videoController?.value.position ?? Duration.zero;

  bool get isAttached => _state != null;

  Future<void> sendBarrage(String content) async {
    final state = _state;
    if (state == null) throw StateError('播放器尚未就绪');
    await state._sendBarrage(content);
  }

  Future<void> selectLine() async {
    final state = _state;
    if (state == null) throw StateError('播放器尚未就绪');
    await state._selectLine();
  }

  void _attach(_PostVideoPlayerState state) => _state = state;

  void _detach(_PostVideoPlayerState state) {
    if (identical(_state, state)) _state = null;
  }
}

class PostVideoPlayer extends StatefulWidget {
  const PostVideoPlayer({
    super.key,
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
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  PostVideoChannel? _selectedChannel;
  Object? _error;
  bool _loading = false;
  bool _danmuEnabled = true;
  final ValueNotifier<bool> _danmuEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<List<PostBarrage>> _barrageNotifier =
      ValueNotifier<List<PostBarrage>>(const <PostBarrage>[]);
  double _lastAudibleVolume = 1;
  double _systemVolume = 1;
  bool _systemVolumeAvailable = false;
  Duration? _seekPreview;
  Duration _dragStartPosition = Duration.zero;
  double? _volumePreview;
  double _applicationBrightness = 0.5;
  double? _brightnessPreview;
  double _verticalDragStartY = 0;
  double _verticalDragStartVolume = 1;
  double _verticalDragStartBrightness = 0.5;
  bool _adjustingVolume = false;
  bool _adjustingBrightness = false;
  StreamSubscription<double>? _systemBrightnessSubscription;
  StreamSubscription<double>? _systemVolumeSubscription;
  final List<PostBarrage> _barrages = <PostBarrage>[];
  int _generation = 0;
  int _barrageGeneration = 0;
  late bool _registrationLocked;

  bool get _isRegistrationLocked {
    return widget.detail.requiresRegistration &&
        !TokenManager.instance.hasToken;
  }

  bool get _canPlay {
    return widget.detail.hasVideo &&
        !_isRegistrationLocked &&
        !widget.detail.requiresCoinUnlock &&
        !widget.detail.requiresVipUnlock;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._attach(this);
    _registrationLocked = _isRegistrationLocked;
    unawaited(_initializeBrightness());
    if (_canPlay) {
      unawaited(_initialize(widget.detail.videoChannels.first));
      unawaited(_loadBarrages());
    }
  }

  @override
  void didUpdateWidget(covariant PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    final wasRegistrationLocked = _registrationLocked;
    _registrationLocked = _isRegistrationLocked;
    final becamePlayable =
        _canPlay &&
        (wasRegistrationLocked ||
            oldWidget.detail.requiresCoinUnlock ||
            oldWidget.detail.requiresVipUnlock);
    final channelsChanged = !_sameChannels(
      oldWidget.detail.videoChannels,
      widget.detail.videoChannels,
    );
    if (!_canPlay) {
      unawaited(_releaseController());
    } else if (becamePlayable || channelsChanged) {
      unawaited(_initialize(widget.detail.videoChannels.first));
      if (becamePlayable || _barrages.isEmpty) unawaited(_loadBarrages());
    }
    if (oldWidget.detail.id != widget.detail.id) {
      _barrages.clear();
      _barrageNotifier.value = const <PostBarrage>[];
      if (_canPlay) unawaited(_loadBarrages());
    }
  }

  Future<void> _loadBarrages() async {
    final generation = ++_barrageGeneration;
    final loaded = <PostBarrage>[];
    var page = 1;
    try {
      while (page <= 5) {
        final result = await PostApi.getBarrages(
          postId: widget.detail.id,
          page: page,
        );
        loaded.addAll(result.items.where((item) => item.content.isNotEmpty));
        if (result.items.isEmpty ||
            result.items.length < 100 ||
            !result.hasMore) {
          break;
        }
        page++;
      }
      if (!mounted || generation != _barrageGeneration) return;
      final seen = <Object>{};
      final unique =
          loaded
              .where((item) {
                final key = item.id > 0
                    ? item.id
                    : Object.hash(item.content, item.playTime.inMilliseconds);
                return seen.add(key);
              })
              .toList(growable: false)
            ..sort(
              (first, second) => first.playTime.compareTo(second.playTime),
            );
      setState(() {
        _barrages
          ..clear()
          ..addAll(unique.take(500));
        _barrageNotifier.value = List<PostBarrage>.unmodifiable(_barrages);
      });
    } catch (_) {
      // 弹幕是播放增强内容，加载失败时保持视频正常播放。
    }
  }

  Future<void> _sendBarrage(String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) throw const FormatException('弹幕内容不能为空');
    final position = _videoController?.value.position ?? Duration.zero;
    await PostApi.sendBarrage(
      postId: widget.detail.id,
      content: normalized,
      playTime: position,
    );
    if (!mounted) return;
    setState(() {
      _barrages.add(
        PostBarrage(
          id: DateTime.now().microsecondsSinceEpoch,
          postId: widget.detail.id,
          content: normalized,
          playTime: position + const Duration(milliseconds: 500),
        ),
      );
      _barrages.sort(
        (first, second) => first.playTime.compareTo(second.playTime),
      );
      _danmuEnabled = true;
      _danmuEnabledNotifier.value = true;
      _barrageNotifier.value = List<PostBarrage>.unmodifiable(_barrages);
    });
  }

  bool _sameChannels(
    List<PostVideoChannel> first,
    List<PostVideoChannel> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].url != second[index].url ||
          first[index].title != second[index].title) {
        return false;
      }
    }
    return true;
  }

  Future<void> _initialize(
    PostVideoChannel channel, {
    Duration resumeAt = Duration.zero,
  }) async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _selectedChannel = channel;
        _loading = true;
        _error = null;
      });
    }

    final oldChewieController = _chewieController;
    _chewieController = null;
    oldChewieController?.dispose();
    final oldController = _videoController;
    _videoController = null;
    if (oldController != null) {
      await oldController.pause();
      await oldController.dispose();
    }

    VideoPlayerController? candidate;
    try {
      final resolvedUrl = VideoUrlResolver.resolve(channel.url);
      final uri = Uri.tryParse(resolvedUrl);
      if (uri == null || !uri.hasScheme) {
        throw const FormatException('Invalid video URL');
      }
      candidate = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      await candidate.initialize();
      if (!mounted || generation != _generation) {
        await candidate.dispose();
        return;
      }
      await candidate.setLooping(false);
      // 手势音量应操作手机媒体音量，不能遗留播放器自身的低增益。
      await candidate.setVolume(1);
      _videoController = candidate;
      unawaited(_initializeSystemVolume());
      if (resumeAt > Duration.zero && resumeAt < candidate.value.duration) {
        await candidate.seekTo(resumeAt);
      }
      _chewieController = ChewieController(
        videoPlayerController: candidate,
        aspectRatio: candidate.value.aspectRatio == 0
            ? 375 / 206
            : candidate.value.aspectRatio,
        autoInitialize: false,
        autoPlay: false,
        looping: false,
        allowedScreenSleep: false,
        showOptions: false,
        playbackSpeeds: const <double>[0.5, 0.75, 1, 1.25, 1.5, 2],
        hideControlsTimer: const Duration(seconds: 3),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: Colors.white38,
          backgroundColor: Colors.white24,
        ),
        deviceOrientationsOnEnterFullScreen: const <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const <DeviceOrientation>[
          DeviceOrientation.portraitUp,
        ],
        customControls: _VideoControls(
          controller: candidate,
          danmuEnabled: _danmuEnabledNotifier,
          onTogglePlayback: () => unawaited(_togglePlayback()),
          onToggleMute: () => unawaited(_toggleMute()),
          onToggleDanmu: _toggleDanmu,
        ),
        overlay: _FanjiaoDanmuOverlay(
          videoController: candidate,
          items: _barrageNotifier,
          enabled: _danmuEnabledNotifier,
        ),
        errorBuilder: (context, _) => _VideoErrorOverlay(
          onRetry: () => unawaited(_initialize(channel, resumeAt: resumeAt)),
        ),
      );
      await candidate.play();
    } catch (error) {
      if (candidate != null && !identical(candidate, _videoController)) {
        await candidate.dispose();
      }
      if (mounted && generation == _generation) _error = error;
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _releaseController() async {
    _generation++;
    final chewieController = _chewieController;
    _chewieController = null;
    chewieController?.dispose();
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;
    if (controller == null) return;
    if (controller.value.position >= controller.value.duration) {
      await controller.seekTo(Duration.zero);
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _selectLine() async {
    if (!_canPlay) {
      showToast('当前内容解锁后才能切换线路', type: ToastType.warning);
      return;
    }
    if (widget.detail.videoChannels.length < 2) {
      showToast('当前只有一条播放线路', type: ToastType.info);
      return;
    }
    final selectedIndex = await showModalActionSheet<String>(
      context: context,
      title: '播放线路切换',
      actions: List<SheetAction<String>>.generate(
        widget.detail.videoChannels.length,
        (index) {
          final channel = widget.detail.videoChannels[index];
          return SheetAction<String>(
            label: channel.title.isEmpty ? '线路${index + 1}' : channel.title,
            key: '$index',
          );
        },
      ),
    );
    final index = int.tryParse(selectedIndex ?? '');
    if (index == null ||
        index < 0 ||
        index >= widget.detail.videoChannels.length) {
      return;
    }

    // 旧版会应用每一次线路选择；即使选择的是当前地址，也需要重新加载并
    // 告知用户结果，不能让弹窗关闭后没有任何反馈。
    final selected = widget.detail.videoChannels[index];
    await _initialize(
      selected,
      resumeAt: _videoController?.value.position ?? Duration.zero,
    );
    if (!mounted) return;
    if (_error == null) {
      showToast(
        '已切换至${selected.title.isEmpty ? '所选线路' : selected.title}',
        type: ToastType.success,
      );
    } else {
      showToast('线路切换失败，请重试', type: ToastType.error);
    }
  }

  Future<void> _toggleMute() async {
    final controller = _videoController;
    if (controller == null) return;
    if (kIsWeb || !_systemVolumeAvailable) {
      final volume = controller.value.volume;
      if (volume > 0) {
        _lastAudibleVolume = volume;
        await controller.setVolume(0);
      } else {
        await controller.setVolume(_lastAudibleVolume.clamp(0.05, 1));
      }
      return;
    }
    final volume = _systemVolume;
    if (volume > 0) {
      _lastAudibleVolume = volume;
      await _setSystemVolume(0);
    } else {
      await _setSystemVolume(_lastAudibleVolume.clamp(0.05, 1));
    }
  }

  void _toggleDanmu() {
    setState(() => _danmuEnabled = !_danmuEnabled);
    _danmuEnabledNotifier.value = _danmuEnabled;
  }

  void _startHorizontalSeek(DragStartDetails details) {
    final controller = _videoController;
    if (controller == null) return;
    _dragStartPosition = controller.value.position;
    setState(() => _seekPreview = _dragStartPosition);
  }

  void _updateHorizontalSeek(DragUpdateDetails details) {
    final controller = _videoController;
    final box = context.findRenderObject() as RenderBox?;
    if (controller == null || box == null || box.size.width <= 0) return;
    final duration = controller.value.duration;
    final offset =
        duration.inMilliseconds * details.primaryDelta! / box.size.width;
    final target =
        (_seekPreview?.inMilliseconds ?? _dragStartPosition.inMilliseconds) +
        offset.round();
    setState(() {
      _seekPreview = Duration(
        milliseconds: target.clamp(0, duration.inMilliseconds),
      );
    });
  }

  Future<void> _endHorizontalSeek(DragEndDetails details) async {
    final target = _seekPreview;
    final controller = _videoController;
    if (target != null && controller != null) await controller.seekTo(target);
    if (mounted) setState(() => _seekPreview = null);
  }

  void _startVerticalAdjustment(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    final controller = _videoController;
    if (box == null || controller == null) return;
    final position = box.globalToLocal(details.globalPosition);
    _verticalDragStartY = position.dy;
    _adjustingBrightness = position.dx < box.size.width / 2;
    _adjustingVolume = !_adjustingBrightness;
    if (_adjustingBrightness) {
      _verticalDragStartBrightness = _applicationBrightness;
      setState(() => _brightnessPreview = _verticalDragStartBrightness);
    } else {
      // video_player 的音量只是应用内增益，最大只能是 1；恢复为 1 后
      // 以系统媒体音量作为手势起点，才能向上调到手机当前音量之上。
      if (kIsWeb || !_systemVolumeAvailable) {
        _verticalDragStartVolume = controller.value.volume;
      } else {
        unawaited(controller.setVolume(1));
        _verticalDragStartVolume = _systemVolume;
      }
      setState(() => _volumePreview = _verticalDragStartVolume);
    }
  }

  void _updateVerticalAdjustment(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    final controller = _videoController;
    if (box == null || controller == null || box.size.height <= 0) return;
    final position = box.globalToLocal(details.globalPosition);
    final delta = (_verticalDragStartY - position.dy) / box.size.height;
    if (_adjustingBrightness) {
      final next = (_verticalDragStartBrightness + delta)
          .clamp(0.0, 1.0)
          .toDouble();
      setState(() => _brightnessPreview = next);
      unawaited(_setApplicationBrightness(next));
      return;
    }
    if (!_adjustingVolume) return;
    final next = (_verticalDragStartVolume + delta).clamp(0.0, 1.0).toDouble();
    setState(() => _volumePreview = next);
    if (kIsWeb || !_systemVolumeAvailable) {
      unawaited(controller.setVolume(next));
    } else {
      unawaited(_setSystemVolume(next));
    }
    if (next > 0) _lastAudibleVolume = next;
  }

  void _endVerticalAdjustment([DragEndDetails? details]) {
    if (_adjustingBrightness && mounted) {
      setState(() => _brightnessPreview = null);
    }
    if (_adjustingVolume && mounted) setState(() => _volumePreview = null);
    _adjustingBrightness = false;
    _adjustingVolume = false;
  }

  Future<void> _initializeBrightness() async {
    if (kIsWeb) return;
    try {
      // 清除旧的应用专属覆盖值，否则 Android 的系统亮度滑块改变的值
      // 会被 Window 的亮度覆盖，用户看起来就像“手机亮度失效”。
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
      final brightness = await ScreenBrightness.instance.system;
      if (!mounted) return;
      setState(() => _applicationBrightness = brightness.clamp(0.0, 1.0));
      _systemBrightnessSubscription = ScreenBrightness
          .instance
          .onSystemScreenBrightnessChanged
          .listen((brightness) => unawaited(_useSystemBrightness(brightness)));
    } catch (_) {
      // Brightness adjustment is unavailable on platforms without this API.
    }
  }

  Future<void> _useSystemBrightness(double brightness) async {
    if (kIsWeb) return;
    try {
      // 左侧手势仍可临时设置播放页亮度；但用户一旦通过系统控件调整，
      // 立即移除覆盖值，让系统亮度重新成为唯一来源。
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // 某些桌面宿主不支持应用亮度重置，保持当前播放不受影响。
    }
    if (!mounted) return;
    setState(() => _applicationBrightness = brightness.clamp(0.0, 1.0));
  }

  Future<void> _setApplicationBrightness(double value) async {
    if (kIsWeb) return;
    final normalized = value.clamp(0.0, 1.0).toDouble();
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(
        normalized,
      );
      _applicationBrightness = normalized;
    } catch (_) {
      // Keep video playback usable when the host denies brightness changes.
    }
  }

  Future<void> _initializeSystemVolume() async {
    if (kIsWeb) return;
    try {
      // 将 Android 实体音量键及插件读写统一绑定到媒体流。
      await FlutterVolumeController.setAndroidAudioStream();
      final volume = await FlutterVolumeController.getVolume();
      if (volume == null) return;
      _systemVolumeAvailable = true;
      _updateSystemVolume(volume);
      if (!mounted) return;
      _systemVolumeSubscription?.cancel();
      _systemVolumeSubscription = FlutterVolumeController.addListener(
        _updateSystemVolume,
        emitOnStart: false,
      );
    } catch (_) {
      _systemVolumeAvailable = false;
      // 平台不支持系统媒体音量时，改用播放器内音量，避免手势失效。
    }
  }

  Future<void> _setSystemVolume(double value) async {
    if (kIsWeb) return;
    final normalized = value.clamp(0.0, 1.0).toDouble();
    try {
      await FlutterVolumeController.setVolume(normalized);
      _updateSystemVolume(normalized);
    } catch (_) {
      // 少数 ROM 会阻止媒体流写入；立即切回播放器音量，确保右侧
      // 手势仍可用，而不会出现“有百分比提示但没有声音变化”。
      _systemVolumeAvailable = false;
      await _videoController?.setVolume(normalized);
    }
  }

  void _updateSystemVolume(double value) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    _systemVolume = normalized;
    if (normalized > 0) _lastAudibleVolume = normalized;
    if (mounted && _adjustingVolume) {
      setState(() => _volumePreview = normalized);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_videoController?.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(this);
    _generation++;
    _barrageGeneration++;
    final chewieController = _chewieController;
    _chewieController = null;
    chewieController?.dispose();
    final controller = _videoController;
    _videoController = null;
    unawaited(controller?.dispose());
    _systemBrightnessSubscription?.cancel();
    _systemVolumeSubscription?.cancel();
    FlutterVolumeController.removeListener();
    unawaited(_resetApplicationBrightness());
    _danmuEnabledNotifier.dispose();
    _barrageNotifier.dispose();
    super.dispose();
  }

  Future<void> _resetApplicationBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // Brightness adjustment is unavailable on platforms without this API.
    }
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    final showCover = shouldShowPostVideoCover(
      isRegistrationLocked: _isRegistrationLocked,
      requiresCoinUnlock: widget.detail.requiresCoinUnlock,
      requiresVipUnlock: widget.detail.requiresVipUnlock,
      hasVideo: widget.detail.hasVideo,
      isLoading: _loading,
      hasError: _error != null,
      hasPlayerController: chewieController != null,
    );

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (showCover) LegacyNetworkImage(url: widget.detail.coverUrl),
          if (_isRegistrationLocked)
            _RegistrationRequiredOverlay(onTap: widget.onLoginRequired)
          else if (widget.detail.requiresCoinUnlock ||
              widget.detail.requiresVipUnlock)
            _LockedVideoOverlay(
              detail: widget.detail,
              onTap: widget.detail.requiresVipUnlock
                  ? widget.onVipUnlockRequired
                  : widget.onCoinUnlockRequired,
            )
          else if (!widget.detail.hasVideo)
            const SizedBox.shrink()
          else if (chewieController != null && !showCover)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _startHorizontalSeek,
              onHorizontalDragUpdate: _updateHorizontalSeek,
              onHorizontalDragEnd: _endHorizontalSeek,
              onVerticalDragStart: _startVerticalAdjustment,
              onVerticalDragUpdate: _updateVerticalAdjustment,
              onVerticalDragEnd: _endVerticalAdjustment,
              onVerticalDragCancel: _endVerticalAdjustment,
              child: Chewie(controller: chewieController),
            ),
          if (_seekPreview case final position?)
            _GestureFeedback(
              icon: Icons.fast_forward_rounded,
              text:
                  '${_formatDuration(position)} / '
                  '${_formatDuration(_videoController?.value.duration ?? Duration.zero)}',
            ),
          if (_volumePreview case final volume?)
            _GestureFeedback(
              icon: volume == 0
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              text: '音量 ${(volume * 100).round()}%',
            ),
          if (_brightnessPreview case final brightness?)
            _GestureFeedback(
              icon: Icons.brightness_6_rounded,
              text: '亮度 ${(brightness * 100).round()}%',
            ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          if (_error != null && !_loading)
            _VideoErrorOverlay(
              onRetry: () {
                final channel = _selectedChannel;
                if (channel != null) unawaited(_initialize(channel));
              },
            ),
        ],
      ),
    );
  }
}

class _LockedVideoOverlay extends StatelessWidget {
  const _LockedVideoOverlay({required this.detail, this.onTap});

  final PostDetail detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final message = detail.requiresVipUnlock
        ? '当前内容需开通VIP，点我立即购买！'
        : '当前内容需付费${_formatPrice(detail.price)}金币购买，点我立即购买！';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 7),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (detail.requiresCoinUnlock)
                Text(
                  '已购买人数：${detail.salesCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _RegistrationRequiredOverlay extends StatelessWidget {
  const _RegistrationRequiredOverlay({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.person_outline_rounded, size: 23),
          label: const Text(
            '登录后观看',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _VideoErrorOverlay extends StatelessWidget {
  const _VideoErrorOverlay({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('播放失败，点击重试'),
        ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({
    required this.controller,
    required this.danmuEnabled,
    required this.onTogglePlayback,
    required this.onToggleMute,
    required this.onToggleDanmu,
  });

  final VideoPlayerController controller;
  final ValueListenable<bool> danmuEnabled;
  final VoidCallback onTogglePlayback;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleDanmu;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  Timer? _hideTimer;
  bool _visible = true;
  bool _speedListVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleVideoChanged);
    _armHideTimer();
  }

  @override
  void didUpdateWidget(covariant _VideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleVideoChanged);
      widget.controller.addListener(_handleVideoChanged);
    }
  }

  void _handleVideoChanged() {
    if (!mounted) return;
    if (!widget.controller.value.isPlaying && !_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = true);
    }
  }

  void _toggleVisibility() {
    _hideTimer?.cancel();
    setState(() {
      _visible = !_visible;
      if (!_visible) _speedListVisible = false;
    });
    if (_visible) _armHideTimer();
  }

  void _armHideTimer() {
    _hideTimer?.cancel();
    if (!widget.controller.value.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
          _speedListVisible = false;
        });
      }
    });
  }

  void _toggleSpeedList() {
    _hideTimer?.cancel();
    setState(() => _speedListVisible = !_speedListVisible);
  }

  void _selectPlaybackSpeed(double speed) {
    widget.controller.setPlaybackSpeed(speed);
    setState(() => _speedListVisible = false);
    _armHideTimer();
  }

  void _runAction(VoidCallback action) {
    action();
    if (!_visible) setState(() => _visible = true);
    _armHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_handleVideoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final chewieController = ChewieController.of(context);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleVisibility,
          child: Stack(
            children: <Widget>[
              IgnorePointer(
                ignoring: !_visible,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Center(
                    child: IconButton(
                      onPressed: () => _runAction(widget.onTogglePlayback),
                      iconSize: 44,
                      color: Colors.white,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !_visible,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 6, 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  '${_formatDuration(value.position)} / '
                                  '${_formatDuration(value.duration)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                _CompactControlButton(
                                  tooltip: value.volume == 0 ? '开启声音' : '静音',
                                  onTap: () => _runAction(widget.onToggleMute),
                                  icon: value.volume == 0
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.danmuEnabled,
                                  builder: (context, enabled, _) {
                                    return _DanmuControlButton(
                                      enabled: enabled,
                                      onTap: () =>
                                          _runAction(widget.onToggleDanmu),
                                    );
                                  },
                                ),
                                _PlaybackSpeedButton(
                                  controller: widget.controller,
                                  onTap: _toggleSpeedList,
                                ),
                                AnimatedBuilder(
                                  animation: chewieController,
                                  builder: (context, _) {
                                    final fullScreen =
                                        chewieController.isFullScreen;
                                    return _CompactControlButton(
                                      tooltip: fullScreen ? '退出全屏' : '全屏',
                                      onTap: () {
                                        if (fullScreen) {
                                          chewieController.exitFullScreen();
                                        } else {
                                          chewieController.enterFullScreen();
                                        }
                                        _armHideTimer();
                                      },
                                      icon: fullScreen
                                          ? Icons.fullscreen_exit_rounded
                                          : Icons.fullscreen_rounded,
                                    );
                                  },
                                ),
                              ],
                            ),
                            VideoProgressIndicator(
                              widget.controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppColors.primary,
                                bufferedColor: Colors.white38,
                                backgroundColor: Colors.white24,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_visible && _speedListVisible)
                _LegacyPlaybackSpeedList(
                  selected: value.playbackSpeed,
                  onSelected: _selectPlaybackSpeed,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactControlButton extends StatelessWidget {
  const _CompactControlButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
      color: Colors.white,
      iconSize: 19,
      icon: Icon(icon),
    );
  }
}

class _DanmuControlButton extends StatelessWidget {
  const _DanmuControlButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: enabled ? '关闭弹幕' : '开启弹幕',
      onPressed: onTap,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
      icon: SvgPicture.asset(
        enabled
            ? 'assets/images/v1/ic_danmu_on.svg'
            : 'assets/images/v1/ic_danmu_off.svg',
        width: 20,
        height: 20,
      ),
    );
  }
}

class _PlaybackSpeedButton extends StatelessWidget {
  const _PlaybackSpeedButton({required this.controller, required this.onTap});

  final VideoPlayerController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = controller.value.playbackSpeed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 32,
        child: Center(
          child: Text(
            current == 1 ? '倍速' : '${_formatSpeed(current)}倍速',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
    );
  }

  static String _formatSpeed(double speed) {
    return speed == speed.truncateToDouble()
        ? speed.toInt().toString()
        : speed.toString();
  }
}

class _LegacyPlaybackSpeedList extends StatelessWidget {
  const _LegacyPlaybackSpeedList({
    required this.selected,
    required this.onSelected,
  });

  static const List<double> _speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

  final double selected;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 50,
      bottom: 70,
      child: Container(
        width: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(3),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _speeds.length,
          itemBuilder: (context, index) {
            final speed = _speeds[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(speed),
              child: Container(
                alignment: Alignment.center,
                height: 18,
                color: speed == selected ? Colors.white10 : Colors.transparent,
                child: Text(
                  speed == 1 ? '正常' : _formatSpeed(speed),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatSpeed(double speed) {
    return speed == speed.truncateToDouble()
        ? speed.toInt().toString()
        : speed.toString();
  }
}

class _GestureFeedback extends StatelessWidget {
  const _GestureFeedback({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 17),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FanjiaoDanmuOverlay extends StatefulWidget {
  const _FanjiaoDanmuOverlay({
    required this.videoController,
    required this.items,
    required this.enabled,
  });

  final VideoPlayerController videoController;
  final ValueListenable<List<PostBarrage>> items;
  final ValueListenable<bool> enabled;

  @override
  State<_FanjiaoDanmuOverlay> createState() => _FanjiaoDanmuOverlayState();
}

class _FanjiaoDanmuOverlayState extends State<_FanjiaoDanmuOverlay> {
  late final DanmuController<_PostDanmuModel> _danmuController;
  Duration _lastVideoPosition = Duration.zero;
  bool _hasLoadedItems = false;

  @override
  void initState() {
    super.initState();
    _danmuController = DanmuController<_PostDanmuModel>(
      adapter: FanjiaoDanmuAdapter<_PostDanmuModel>(rowHeight: 30),
      maxSize: 500,
      filter: DanmuFlag.scroll | DanmuFlag.repeated,
    );
    _lastVideoPosition = widget.videoController.value.position;
    widget.videoController.addListener(_synchronizeWithVideo);
    widget.items.addListener(_reloadItems);
    widget.enabled.addListener(_synchronizePlaybackState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadItems();
      _synchronizeWithVideo();
    });
  }

  @override
  void didUpdateWidget(covariant _FanjiaoDanmuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController) {
      oldWidget.videoController.removeListener(_synchronizeWithVideo);
      widget.videoController.addListener(_synchronizeWithVideo);
      _lastVideoPosition = widget.videoController.value.position;
      _reloadItems();
    }
    if (oldWidget.items != widget.items) {
      oldWidget.items.removeListener(_reloadItems);
      widget.items.addListener(_reloadItems);
      _reloadItems();
    }
    if (oldWidget.enabled != widget.enabled) {
      oldWidget.enabled.removeListener(_synchronizePlaybackState);
      widget.enabled.addListener(_synchronizePlaybackState);
      _synchronizePlaybackState();
    }
  }

  void _reloadItems() {
    if (!_danmuController.isEnable) return;
    final videoValue = widget.videoController.value;
    _danmuController
      ..clearDanmu()
      ..setDuration(videoValue.duration)
      ..addAllDanmu(_createModels(widget.items.value))
      ..progress = videoValue.position;
    _lastVideoPosition = videoValue.position;
    _hasLoadedItems = true;
    _synchronizePlaybackState();
  }

  Iterable<_PostDanmuModel> _createModels(List<PostBarrage> items) sync* {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      yield _PostDanmuModel(
        item,
        Object.hash(item.id, item.playTime.inMilliseconds, index),
      );
    }
  }

  void _synchronizeWithVideo() {
    if (!_danmuController.isEnable) return;
    final videoValue = widget.videoController.value;
    final position = videoValue.position;
    final movedBackwards =
        position + const Duration(milliseconds: 700) < _lastVideoPosition;
    if (movedBackwards) {
      _reloadItems();
      return;
    }
    if (!_hasLoadedItems) {
      _reloadItems();
      return;
    }
    final drift = (_danmuController.progress - position).abs();
    if (drift > const Duration(milliseconds: 450)) {
      _danmuController.progress = position;
    }
    _lastVideoPosition = position;
    _danmuController.rate = videoValue.playbackSpeed;
    _synchronizePlaybackState();
  }

  void _synchronizePlaybackState() {
    if (!_danmuController.isEnable) return;
    final shouldPlay =
        widget.enabled.value && widget.videoController.value.isPlaying;
    if (shouldPlay) {
      if (_danmuController.state != DanmuStatus.playing &&
          _danmuController.state != DanmuStatus.idle) {
        _danmuController.start();
      }
    } else if (_danmuController.state != DanmuStatus.pause) {
      _danmuController.pause();
    }
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_synchronizeWithVideo);
    widget.items.removeListener(_reloadItems);
    widget.enabled.removeListener(_synchronizePlaybackState);
    // DanmuWidget owns and disposes the fanjiao_danmu controller.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight * 0.72;
            if (!width.isFinite || !height.isFinite || height < 30) {
              return const SizedBox.shrink();
            }
            return ValueListenableBuilder<bool>(
              valueListenable: widget.enabled,
              builder: (context, enabled, _) {
                return AnimatedOpacity(
                  opacity: enabled ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: ClipRect(
                    child: DanmuWidget(
                      width: width,
                      height: height,
                      danmuController: _danmuController,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _PostDanmuModel extends DanmuModel {
  _PostDanmuModel(PostBarrage item, int stableId)
    : super(
        id: stableId,
        text: item.content,
        startTime: item.playTime,
        isClickable: false,
        isRepeatable: true,
        flag: DanmuFlag.scroll | DanmuFlag.repeated,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
          shadows: <Shadow>[
            Shadow(color: Colors.black, blurRadius: 2),
            Shadow(color: Colors.black, offset: Offset(1, 1)),
          ],
        ),
      );
}

String _formatDuration(Duration value) {
  final seconds = value.inSeconds < 0 ? 0 : value.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}
