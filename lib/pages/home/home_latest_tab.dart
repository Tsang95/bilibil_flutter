import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/pages/home/components/home_latest_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class HomeLatestTab extends StatefulWidget {
  const HomeLatestTab({super.key});

  @override
  State<HomeLatestTab> createState() => _HomeLatestTabState();
}

class _HomeLatestTabState extends State<HomeLatestTab>
    with AutomaticKeepAliveClientMixin<HomeLatestTab> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();
  List<TopicSummary> _topics = const <TopicSummary>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) =>
          HomeApi.getLatest(page: page, forceRefresh: forceRefresh),
    );
    _scrollController.addListener(_handleScroll);
    unawaited(_loadInitial());
  }

  Future<void> _loadInitial() async {
    await Future.wait<void>(<Future<void>>[
      _controller.loadInitial().catchError((_) {}),
      _loadTopics(forceRefresh: false).catchError((_) {}),
    ]);
  }

  Future<void> _loadTopics({required bool forceRefresh}) async {
    final topics = await HomeApi.getTopics(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() => _topics = topics.take(8).toList(growable: false));
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
        action: () async {
          await Future.wait<void>(<Future<void>>[
            _controller.refresh(),
            _loadTopics(forceRefresh: true),
          ]);
        },
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
    super.build(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const PageStorageKey<String>('home_latest_rank'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: _buildSlivers(),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/ic_hot_huati.svg',
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  '热门话题',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed<void>(AppRoutes.searchTopic),
                child: const Row(
                  children: <Widget>[
                    Text(
                      '查看更多',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (_topics.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          sliver: SliverGrid.builder(
            itemCount: _topics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 5,
              mainAxisExtent: 18,
            ),
            itemBuilder: (context, index) {
              final topic = _topics[index];
              return GestureDetector(
                onTap: () =>
                    Get.toNamed<void>(AppRoutes.topicList, arguments: topic),
                child: Text(
                  topic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      const SliverToBoxAdapter(child: Divider(height: 0.5)),
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
    slivers.add(
      SliverList.builder(
        itemCount: _controller.items.length,
        itemBuilder: (context, index) =>
            HomeLatestPostCard(post: _controller.items[index]),
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
