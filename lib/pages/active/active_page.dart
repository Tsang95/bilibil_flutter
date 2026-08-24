import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/pages/active/active_feed_controller.dart';
import 'package:b_flutter/pages/active/components/active_post_card.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class ActivePage extends StatefulWidget {
  const ActivePage({super.key});

  @override
  State<ActivePage> createState() => _ActivePageState();
}

class _ActivePageState extends State<ActivePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  Future<void> _createActive() async {
    if (!TokenManager.instance.hasToken) {
      final result = await Get.toNamed(AppRoutes.login);
      if (result != true || !mounted) return;
    }
    await Get.toNamed<void>(AppRoutes.createActive);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFE5E5E5),
                      ),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.search,
                          size: 15,
                          color: Color(0xFFAAAAAA),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '搜索',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => unawaited(_createActive()),
                  child: const Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(
                          CupertinoIcons.add_circled,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '发帖',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2, color: AppColors.primary),
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textPrimary,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: const <Widget>[
              Tab(text: '全部'),
              Tab(text: '视频'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                _ActiveFeed(type: 0),
                _ActiveFeed(type: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFeed extends StatefulWidget {
  const _ActiveFeed({required this.type});

  final int type;

  @override
  State<_ActiveFeed> createState() => _ActiveFeedState();
}

class _ActiveFeedState extends State<_ActiveFeed>
    with AutomaticKeepAliveClientMixin<_ActiveFeed> {
  late final ActiveFeedController _controller = ActiveFeedController(
    type: widget.type,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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
    super.build(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          key: PageStorageKey<String>('active_${widget.type}'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: _slivers(),
        ),
      ),
    );
  }

  List<Widget> _slivers() {
    if (_controller.initialLoading && _controller.items.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_controller.error != null && _controller.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: _refresh,
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
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                '暂无数据',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      SliverList.separated(
        itemCount: _controller.items.length,
        itemBuilder: (context, index) =>
            ActivePostCard(post: _controller.items[index]),
        separatorBuilder: (_, _) => const SizedBox(
          height: 10,
          child: ColoredBox(color: Color(0xFFF1F2F3)),
        ),
      ),
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
    ];
  }
}
