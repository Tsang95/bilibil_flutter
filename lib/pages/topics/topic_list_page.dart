import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/pages/topics/components/topic_post_card.dart';
import 'package:b_flutter/pages/topics/topic_posts_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class TopicListPage extends StatefulWidget {
  const TopicListPage({super.key, required this.topic});

  final TopicSummary topic;

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  late final TopicPostsController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TopicPostsController(widget.topic.id);
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
        fallbackErrorMessage: '刷新失败，请稍后重试',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: const LegacyAppBar(title: '话题中心'),
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
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.topic.title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text(
                widget.topic.description,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_compactCount(widget.topic.viewCount)}+浏览•${_compactCount(widget.topic.commentCount)}+讨论',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
    ];

    if (_controller.initialLoading && _controller.items.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
      return slivers;
    }
    if (_controller.error != null && _controller.items.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('加载失败，点击重试'),
            ),
          ),
        ),
      );
      return slivers;
    }
    if (_controller.items.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无内容',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverList.builder(
        itemCount: _controller.items.length,
        itemBuilder: (context, index) =>
            TopicPostCard(post: _controller.items[index]),
      ),
    );
    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(
          height: _controller.loadingMore ? 36 : (_controller.hasMore ? 0 : 28),
          child: Center(
            child: _controller.loadingMore
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : Text(
                    _controller.hasMore ? '' : '没有更多了',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
      ),
    );
    return slivers;
  }
}

String _compactCount(int value) {
  if (value >= 10000) {
    final count = value / 10000;
    return '${count.toStringAsFixed(count >= 10 ? 0 : 1)}万';
  }
  return '$value';
}
