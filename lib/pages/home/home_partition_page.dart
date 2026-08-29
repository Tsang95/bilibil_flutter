import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_forum_post_card.dart';
import 'package:b_flutter/pages/home/components/home_grid_advertisement_card.dart';
import 'package:b_flutter/pages/home/components/home_portrait_post_card.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';

final class HomePartitionArguments {
  const HomePartitionArguments({
    required this.category,
    required this.banners,
    required this.contentAds,
  });

  final HomeCategory category;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;
}

class HomePartitionPage extends StatelessWidget {
  const HomePartitionPage({super.key, required this.arguments});

  final HomePartitionArguments arguments;

  @override
  Widget build(BuildContext context) {
    final children = arguments.category.children;
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: LegacyAppBar(
        title: arguments.category.name,
        trailing: GestureDetector(
          onTap: () => Get.toNamed<void>(AppRoutes.search),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              'assets/images/ic_search.svg',
              width: 18,
              height: 18,
            ),
          ),
        ),
      ),
      body: children.isEmpty
          ? const SizedBox.shrink()
          : DefaultTabController(
              length: children.length,
              child: Column(
                children: <Widget>[
                  ColoredBox(
                    color: AppColors.surface,
                    child: SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 2,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textPrimary,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 14),
                        tabs: <Widget>[
                          for (final child in children) Tab(text: child.name),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        for (final child in children)
                          _HomePartitionTab(
                            parent: arguments.category,
                            category: child,
                            banners: arguments.banners,
                            contentAds: arguments.contentAds,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HomePartitionTab extends StatefulWidget {
  const _HomePartitionTab({
    required this.parent,
    required this.category,
    required this.banners,
    required this.contentAds,
  });

  final HomeCategory parent;
  final HomeCategory category;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;

  @override
  State<_HomePartitionTab> createState() => _HomePartitionTabState();
}

class _HomePartitionTabState extends State<_HomePartitionTab>
    with AutomaticKeepAliveClientMixin<_HomePartitionTab> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  final Map<int, BannerItem> _advertisements = <int, BannerItem>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) => HomeApi.getCategoryPosts(
        categoryId: widget.parent.id,
        childCategoryId: widget.category.id,
        page: page,
        sort: 1,
        size: 0,
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
    _advertisements.clear();
    try {
      await _controller.refresh();
    } catch (_) {}
  }

  BannerItem _advertisementFor(int slot) {
    return _advertisements.putIfAbsent(
      slot,
      () => widget.contentAds[_random.nextInt(widget.contentAds.length)],
    );
  }

  List<Object> _entries() {
    if (widget.parent.id == 6 || widget.contentAds.isEmpty) {
      return List<Object>.from(_controller.items);
    }
    final entries = <Object>[];
    for (var index = 0; index < _controller.items.length; index++) {
      if (index != 0 && index % 6 == 0) {
        entries.add(_advertisementFor(index ~/ 6));
      }
      entries.add(_controller.items[index]);
    }
    return entries;
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
          key: PageStorageKey<String>(
            'home_partition_${widget.parent.id}_${widget.category.id}',
          ),
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
    final entries = _entries();
    final slivers = <Widget>[
      if (widget.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: HomeBannerCarousel(items: widget.banners),
          ),
        ),
    ];

    if (_controller.initialLoading && entries.isEmpty) {
      return <Widget>[
        ...slivers,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_controller.error != null && entries.isEmpty) {
      return <Widget>[
        ...slivers,
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
    if (entries.isEmpty) {
      return <Widget>[
        ...slivers,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无帖子',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      ];
    }

    if (widget.parent.id == 83) {
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
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          ),
        ),
      );
    } else if (widget.parent.id == 6) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverGrid.builder(
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              childAspectRatio: 115 / 228,
            ),
            itemBuilder: (context, index) =>
                HomePortraitPostCard(post: entries[index] as PostSummary),
          ),
        ),
      );
    } else {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          sliver: SliverGrid.builder(
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return entry is BannerItem
                  ? HomeGridAdvertisementCard(banner: entry)
                  : HomePostCard(post: entry as PostSummary);
            },
          ),
        ),
      );
    }

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
