import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/fan_user.dart';
import 'package:b_flutter/pages/mine/my_fans_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class MyFansPage extends StatefulWidget {
  const MyFansPage({super.key});

  @override
  State<MyFansPage> createState() => _MyFansPageState();
}

class _MyFansPageState extends State<MyFansPage> {
  final _scrollController = ScrollController();
  late final MyFansController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MyFansController();
    _scrollController.addListener(_handleScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _controller.loadInitial();
    } catch (_) {
      // The retry state is rendered below.
    }
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 240) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _follow(FanUser user) async {
    if (_controller.isSubmitting(user)) return;
    try {
      await SubmissionFeedback.run<void>(
        action: () => _controller.follow(user),
        loadingMessage: user.isFollowing ? '取消关注中...' : '关注中...',
        successMessage: user.isFollowing ? '已取消关注' : '关注成功',
      );
    } catch (_) {
      // SubmissionFeedback has shown the backend error.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '我的粉丝'),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _buildBody(),
    ),
  );

  Widget _buildBody() {
    final fans = _controller.items;
    if (_controller.initialLoading && fans.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_controller.error != null && fans.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(_load()),
          child: const Text('加载失败，点击重试'),
        ),
      );
    }
    if (fans.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(10),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: fans.length + 1,
        itemBuilder: (context, index) => index == fans.length
            ? _FansFooter(
                loading: _controller.loadingMore,
                hasMore: _controller.hasMore,
              )
            : _FanTile(
                fan: fans[index],
                submitting: _controller.isSubmitting(fans[index]),
                onTap: () => unawaited(_follow(fans[index])),
              ),
        separatorBuilder: (_, index) => index == fans.length - 1
            ? const SizedBox.shrink()
            : const Divider(height: .5, color: Color(0xFFE5E5E5)),
      ),
    );
  }
}

class _FanTile extends StatelessWidget {
  const _FanTile({
    required this.fan,
    required this.submitting,
    required this.onTap,
  });
  final FanUser fan;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final followed = fan.isFollowing;
    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 35,
            height: 35,
            child: LegacyNetworkImage(
              url: fan.avatarUrl,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                Text(
                  fan.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.person_2,
                      size: 12,
                      color: AppColors.navigationUnselected,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatCount(fan.fanCount),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _timeAge(fan.lastActiveAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            height: 24,
            child: OutlinedButton(
              onPressed: submitting ? null : onTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: followed ? AppColors.primary : Colors.white,
                foregroundColor: followed
                    ? Colors.white
                    : AppColors.navigationUnselected,
                side: followed
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.navigationUnselected),
                shape: const StadiumBorder(),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: submitting
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      followed ? '已关注' : '关注',
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FansFooter extends StatelessWidget {
  const _FansFooter({required this.loading, required this.hasMore});
  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: loading || !hasMore ? 36 : 0,
    child: Center(
      child: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : hasMore
          ? null
          : const Text(
              '没有更多了',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
    ),
  );
}

String _formatCount(int value) {
  if (value < 10000) return '$value';
  return '${(value / 10000).toStringAsFixed(1)}万';
}

String _timeAge(DateTime? value) {
  if (value == null) return '';
  final elapsed = DateTime.now().difference(value).abs();
  if (elapsed.inMinutes < 5) return '刚刚';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}分钟之前';
  if (elapsed.inHours < 24) return '${elapsed.inHours}小时之前';
  if (elapsed.inDays < 7) return '${elapsed.inDays}天前';
  if (elapsed.inDays == 7) return '1周前';
  if (elapsed.inDays > 8 && elapsed.inDays < 30) return '${elapsed.inDays}天前';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
