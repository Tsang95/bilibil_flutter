import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_forum_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class HomeForumTab extends StatefulWidget {
  const HomeForumTab({
    super.key,
    required this.category,
    required this.banners,
    required this.contentAds,
  });

  final HomeCategory category;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;

  @override
  State<HomeForumTab> createState() => _HomeForumTabState();
}

class _HomeForumTabState extends State<HomeForumTab>
    with AutomaticKeepAliveClientMixin<HomeForumTab> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryId = 0;
  bool _showAllCategories = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) => HomeApi.getCategoryPosts(
        categoryId: widget.category.id,
        childCategoryId: _selectedCategoryId,
        page: page,
        size: 10,
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

  Future<void> _refresh({String successMessage = '刷新成功'}) async {
    try {
      await SubmissionFeedback.run<void>(
        action: _controller.refresh,
        successMessage: successMessage,
        fallbackErrorMessage: '刷新失败，请稍后重试',
        lock: false,
      );
    } catch (_) {}
  }

  Future<void> _selectCategory(int id) async {
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
    await _refresh(successMessage: '筛选已更新');
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
          key: PageStorageKey<String>('home_forum_${widget.category.id}'),
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
    final categories = <HomeCategory>[
      HomeCategory.fromJson(const <String, dynamic>{'id': 0, 'name': '全部'}),
      ...widget.category.children,
    ];
    final visibleCategories = _showAllCategories || categories.length < 8
        ? categories
        : categories.take(8).toList(growable: false);
    final entries = <Object>[];
    for (var index = 0; index < _controller.items.length; index++) {
      if (index > 0 && index % 5 == 0 && widget.contentAds.isNotEmpty) {
        entries.add(
          widget.contentAds[(index ~/ 5 - 1) % widget.contentAds.length],
        );
      }
      entries.add(_controller.items[index]);
    }

    final slivers = <Widget>[
      if (widget.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: HomeBannerCarousel(items: widget.banners),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid.builder(
          itemCount: visibleCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 64 / 30,
          ),
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            final selected = category.id == _selectedCategoryId;
            return InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _selectCategory(category.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: InkWell(
          onTap: () => setState(() => _showAllCategories = !_showAllCategories),
          child: SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _showAllCategories ? '收起' : '展开查看更多',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                SvgPicture.asset(
                  'assets/images/ic_expand.svg',
                  width: 11,
                  height: 11,
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    if (_controller.initialLoading && entries.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
      return slivers;
    }
    if (_controller.error != null && entries.isEmpty) {
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
    if (entries.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无帖子',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
      return slivers;
    }
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.all(8),
        sliver: SliverList.separated(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return entry is BannerItem
                ? HomeForumAdCard(banner: entry)
                : HomeForumPostCard(post: entry as PostSummary);
          },
          separatorBuilder: (_, _) => const SizedBox(height: 8),
        ),
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
