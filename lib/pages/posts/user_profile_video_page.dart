import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/pages/posts/components/user_profile_post_card.dart';

enum UserProfileVideoType {
  liked(apiValue: 1, title: '点赞视频'),
  purchased(apiValue: 2, title: '购买视频'),
  collected(apiValue: 3, title: '收藏视频'),
  coined(apiValue: 4, title: '投币视频');

  const UserProfileVideoType({required this.apiValue, required this.title});

  final int apiValue;
  final String title;
}

final class UserProfileVideoArguments {
  const UserProfileVideoArguments({required this.userId, required this.type});

  final int userId;
  final UserProfileVideoType type;
}

class UserProfileVideoPage extends StatefulWidget {
  const UserProfileVideoPage({super.key, required this.arguments, this.loader});

  final UserProfileVideoArguments arguments;
  final HomePageLoader? loader;

  @override
  State<UserProfileVideoPage> createState() => _UserProfileVideoPageState();
}

class _UserProfileVideoPageState extends State<UserProfileVideoPage> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      widget.loader ??
          (page, forceRefresh) => PostApi.getUserProfileVideos(
            userId: widget.arguments.userId,
            type: widget.arguments.type.apiValue,
            page: page,
            forceRefresh: forceRefresh,
          ),
    );
    _scrollController.addListener(_loadMoreWhenNeeded);
    unawaited(_controller.loadInitial().catchError((_) {}));
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 260) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _refresh() async {
    try {
      await _controller.refresh();
    } catch (_) {
      // The explicit retry state below keeps the backend error visible.
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceMuted,
    appBar: LegacyAppBar(title: widget.arguments.type.title),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: _buildSlivers(),
        ),
      ),
    ),
  );

  List<Widget> _buildSlivers() {
    if (_controller.initialLoading && _controller.items.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      ];
    }
    if (_controller.error != null && _controller.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: () => unawaited(_refresh()),
              child: const Text('加载失败，点击重试'),
            ),
          ),
        ),
      ];
    }
    if (_controller.items.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无数据',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        sliver: SliverGrid.builder(
          itemCount: _controller.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 173 / 145,
          ),
          itemBuilder: (context, index) =>
              UserProfilePostCard(post: _controller.items[index]),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 48,
          child: Center(
            child: _controller.loadingMore
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _controller.hasMore ? '上拉加载更多' : '没有更多了',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }
}
