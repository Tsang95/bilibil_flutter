import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/search_user.dart';
import 'package:b_flutter/pages/search/search_user_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class SearchUsersView extends StatefulWidget {
  const SearchUsersView({super.key, required this.keyword});

  final String keyword;

  @override
  State<SearchUsersView> createState() => _SearchUsersViewState();
}

class _SearchUsersViewState extends State<SearchUsersView>
    with AutomaticKeepAliveClientMixin {
  late final SearchUserController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = SearchUserController(widget.keyword);
    _scrollController.addListener(_handleScroll);
    unawaited(_controller.load().catchError((_) {}));
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 260) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    try {
      await _controller.loadMore();
    } catch (_) {
      // The footer exposes a stable retry action without interrupting reading.
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: () => _controller.load(forceRefresh: true),
        successMessage: '用户结果已刷新',
        fallbackErrorMessage: '用户结果刷新失败',
        lock: false,
      );
    } catch (_) {}
  }

  Future<void> _toggleFollow(SearchUser user) async {
    try {
      await _controller.toggleFollow(user);
    } catch (_) {
      // The shared submission wrapper has already shown the backend error.
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && _controller.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView.builder(
            key: PageStorageKey<String>('search-users-${widget.keyword}'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _itemCount,
            itemBuilder: _buildItem,
          ),
        );
      },
    );
  }

  int get _itemCount {
    if (_controller.items.isNotEmpty) return _controller.items.length + 1;
    return 1;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (_controller.items.isEmpty) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _controller.error == null ? '没有找到相关用户' : '用户结果加载失败',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              if (_controller.error != null)
                TextButton(
                  onPressed: () => unawaited(_refresh()),
                  child: const Text('重新加载'),
                ),
            ],
          ),
        ),
      );
    }

    if (index == _controller.items.length) return _buildLoadMoreFooter();

    final user = _controller.items[index];
    return InkWell(
      onTap: () => Get.toNamed<void>(AppRoutes.userProfilePath(user.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 78,
              child: Row(
                children: <Widget>[
                  SizedBox.square(
                    dimension: 48,
                    child: LegacyNetworkImage(
                      url: user.avatarUrl,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: user.movieLevel > 0
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user.fanCount}粉丝•${user.workCount}作品',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FollowButton(
                    following: user.isFollowing,
                    submitting: _controller.isSubmitting(user.id),
                    onTap: () => unawaited(_toggleFollow(user)),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_controller.loadingMore) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (_controller.loadMoreError != null) {
      return SizedBox(
        height: 44,
        child: Center(
          child: TextButton(
            onPressed: () => unawaited(_loadMore()),
            child: const Text('加载失败，点击重试'),
          ),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: Center(
        child: Text(
          _controller.hasMore ? '继续上滑加载更多' : '没有更多用户了',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.following,
    required this.submitting,
    required this.onTap,
  });

  final bool following;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 28,
      child: OutlinedButton(
        onPressed: submitting ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor:
              following ? AppColors.textTertiary : AppColors.primary,
          side: BorderSide(
            color: following ? AppColors.divider : AppColors.primary,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: submitting
            ? const SizedBox.square(
                dimension: 13,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : Text(
                following ? '已关注' : '关注',
                style: const TextStyle(fontSize: 12),
              ),
      ),
    );
  }
}
