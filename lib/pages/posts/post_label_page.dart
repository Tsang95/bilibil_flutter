import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/pages/posts/components/post_tag_post_card.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

/// Displays the lazy, paginated post list for a detail-page label.
class PostLabelPage extends StatefulWidget {
  const PostLabelPage({super.key, required this.label});

  final PostLabel label;

  @override
  State<PostLabelPage> createState() => _PostLabelPageState();
}

class _PostLabelPageState extends State<PostLabelPage> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) => PostApi.getPostsByLabel(
        labelId: widget.label.id,
        page: page,
        forceRefresh: forceRefresh,
      ),
    );
    _scrollController.addListener(_handleScroll);
    unawaited(_controller.loadInitial().catchError((_) {}));
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 360) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: _controller.refresh,
        successMessage: '标签内容已刷新',
        fallbackErrorMessage: '标签内容刷新失败',
        lock: false,
      );
    } catch (_) {
      // SubmissionFeedback already shows the failure result.
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: LegacyAppBar(
        title: '#${widget.label.name.isEmpty ? '标签' : widget.label.name}',
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _buildSlivers(),
          ),
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
          child: _PostLabelMessage(
            message: '标签内容加载失败',
            actionText: '重新加载',
            onAction: () => unawaited(_refresh()),
          ),
        ),
      ];
    }
    if (_controller.items.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _PostLabelMessage(message: '该标签下暂无内容'),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.all(10),
        sliver: SliverGrid.builder(
          itemCount: _controller.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 168,
          ),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: PostTagPostCard(post: _controller.items[index]),
          ),
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

class _PostLabelMessage extends StatelessWidget {
  const _PostLabelMessage({
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
