import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/home_label.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_grid_advertisement_card.dart';
import 'package:b_flutter/pages/home/components/home_portrait_post_card.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';

final class HomeMorePostsArguments {
  const HomeMorePostsArguments({
    required this.parent,
    required this.category,
    required this.banners,
    required this.contentAds,
  });

  final HomeCategory parent;
  final HomeCategory category;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;
}

class HomeMorePostsPage extends StatefulWidget {
  const HomeMorePostsPage({super.key, required this.arguments});

  final HomeMorePostsArguments arguments;

  @override
  State<HomeMorePostsPage> createState() => _HomeMorePostsPageState();
}

class _HomeMorePostsPageState extends State<HomeMorePostsPage> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  final Map<int, BannerItem> _advertisements = <int, BannerItem>{};
  List<HomeLabel> _labels = const <HomeLabel>[];
  int _selectedLabel = 0;
  bool _expanded = false;

  int get _selectedLabelId {
    if (_selectedLabel < 0 || _selectedLabel >= _labels.length) return 0;
    return _labels[_selectedLabel].id;
  }

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) => HomeApi.getCategoryPosts(
        categoryId: widget.arguments.parent.id,
        childCategoryId: widget.arguments.category.id,
        page: page,
        sort: 3,
        size: widget.arguments.parent.id == 6 ? 9 : 10,
        labelId: _selectedLabelId,
        forceRefresh: forceRefresh,
      ),
    );
    _scrollController.addListener(_handleScroll);
    unawaited(_loadInitial());
  }

  Future<void> _loadInitial() async {
    try {
      final labels = await HomeApi.getCategoryLabels(
        categoryId: widget.arguments.category.id,
      );
      if (mounted) {
        setState(() {
          _labels = <HomeLabel>[const HomeLabel(id: 0, name: '全部'), ...labels];
        });
      }
    } catch (_) {}
    try {
      await _controller.loadInitial();
    } catch (_) {}
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

  Future<void> _selectLabel(int index) async {
    setState(() => _selectedLabel = _selectedLabel == index ? -1 : index);
    await _refresh();
  }

  BannerItem _advertisementFor(int slot) {
    return _advertisements.putIfAbsent(
      slot,
      () =>
          widget.arguments.contentAds[_random.nextInt(
            widget.arguments.contentAds.length,
          )],
    );
  }

  List<Object> _entries() {
    if (widget.arguments.parent.id == 6 ||
        widget.arguments.contentAds.isEmpty) {
      return List<Object>.from(_controller.items);
    }
    final entries = <Object>[];
    for (var index = 0; index < _controller.items.length; index++) {
      final pageIndex = index ~/ 10;
      final indexInPage = index % 10;
      if (indexInPage == 4) {
        entries.add(_advertisementFor(pageIndex * 2));
      }
      entries.add(_controller.items[index]);
      if (indexInPage == 9) {
        entries.add(_advertisementFor(pageIndex * 2 + 1));
      }
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
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: LegacyAppBar(title: widget.arguments.category.name),
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
    final visibleLabelCount = _expanded || _labels.length < 8
        ? _labels.length
        : 8;
    final entries = _entries();
    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      if (widget.arguments.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverToBoxAdapter(
            child: HomeBannerCarousel(items: widget.arguments.banners),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      if (visibleLabelCount > 0)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverGrid.builder(
            itemCount: visibleLabelCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 80 / 32,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final selected = _selectedLabel == index;
              return GestureDetector(
                onTap: () => _selectLabel(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      _labels[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _expanded ? '收起更多' : '展开更多',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 11,
                  color: AppColors.textTertiary,
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
        padding: EdgeInsets.symmetric(
          horizontal: widget.arguments.parent.id == 6 ? 7 : 10,
        ),
        sliver: SliverGrid.builder(
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.arguments.parent.id == 6 ? 3 : 2,
            childAspectRatio: widget.arguments.parent.id == 6 ? 115 / 228 : 1,
            mainAxisSpacing: widget.arguments.parent.id == 6 ? 0 : 4,
            crossAxisSpacing: widget.arguments.parent.id == 6 ? 6 : 4,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            if (entry is BannerItem) {
              return HomeGridAdvertisementCard(banner: entry);
            }
            final post = entry as PostSummary;
            return widget.arguments.parent.id == 6
                ? HomePortraitPostCard(post: post)
                : HomePostCard(post: post);
          },
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
