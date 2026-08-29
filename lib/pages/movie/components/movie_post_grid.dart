import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/pages/movie/components/movie_post_card.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class MoviePostGrid extends StatefulWidget {
  const MoviePostGrid({
    super.key,
    required this.storageKey,
    required this.loader,
    this.emptyMessage = '暂无影视内容',
  });

  final String storageKey;
  final Future<PagedResult<PostSummary>> Function(int page, bool forceRefresh)
      loader;
  final String emptyMessage;

  @override
  State<MoviePostGrid> createState() => _MoviePostGridState();
}

class _MoviePostGridState extends State<MoviePostGrid> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(widget.loader);
    _scrollController.addListener(_handleScroll);
    unawaited(_controller.loadInitial().catchError((_) {}));
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 320) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: _controller.refresh,
        successMessage: '刷新成功',
        fallbackErrorMessage: '影视内容刷新失败',
        lock: false,
      );
    } catch (_) {}
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          key: PageStorageKey<String>(widget.storageKey),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _buildSlivers(),
        ),
      ),
    );
  }

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
          child: _MovieGridMessage(
            message: '影视内容加载失败',
            actionText: '重新加载',
            onAction: () => unawaited(_refresh()),
          ),
        ),
      ];
    }
    if (_controller.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MovieGridMessage(message: widget.emptyMessage),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        sliver: SliverGrid.builder(
          itemCount: _controller.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            mainAxisExtent: 140,
          ),
          itemBuilder: (context, index) =>
              MoviePostCard(post: _controller.items[index]),
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
                    _controller.hasMore ? '' : '已经到底了',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }
}

class _MovieGridMessage extends StatelessWidget {
  const _MovieGridMessage({
    required this.message,
    this.actionText,
    this.onAction,
  });

  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          if (actionText != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
        ],
      ),
    );
  }
}
