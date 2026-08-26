import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_grid_advertisement_card.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

typedef SortedHomePageLoader =
    Future<PagedResult<PostSummary>> Function(
      int page,
      bool forceRefresh,
      int sortType,
    );

@visibleForTesting
List<Object> buildHomeRecommendationEntries({
  required List<PostSummary> posts,
  required List<BannerItem> advertisements,
  BannerItem Function(int pageIndex, int slot)? selectAdvertisement,
}) {
  if (posts.isEmpty || advertisements.isEmpty) return <Object>[...posts];
  final entries = <Object>[];
  for (var pageStart = 0; pageStart < posts.length; pageStart += 16) {
    final pageIndex = pageStart ~/ 16;
    final pageEnd = min(pageStart + 16, posts.length);
    final pageEntries = <Object>[...posts.sublist(pageStart, pageEnd)];
    BannerItem advertisementFor(int slot) =>
        selectAdvertisement?.call(pageIndex, slot) ??
        advertisements[(pageIndex * 2 + slot) % advertisements.length];
    if (pageEntries.length >= 7) {
      pageEntries.insert(7, advertisementFor(0));
    }
    if (pageEntries.length >= 13) {
      pageEntries.insert(13, advertisementFor(1));
    }
    entries.addAll(pageEntries);
  }
  return entries;
}

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({
    super.key,
    required this.loader,
    this.banners = const <BannerItem>[],
    this.advertisements = const <BannerItem>[],
    this.showSort = false,
  });

  final SortedHomePageLoader loader;
  final List<BannerItem> banners;
  final List<BannerItem> advertisements;
  final bool showSort;

  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab>
    with AutomaticKeepAliveClientMixin<HomeFeedTab> {
  late final HomeFeedController _controller;
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  final Map<int, BannerItem> _advertisements = <int, BannerItem>{};
  _HomeSort _sort = _HomeSort.hottest;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController(
      (page, forceRefresh) => widget.loader(page, forceRefresh, _sort.value),
    );
    _scrollController.addListener(_handleScroll);
    unawaited(_controller.loadInitial().catchError((_) {}));
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 360) {
      unawaited(_controller.loadMore());
    }
  }

  @override
  void didUpdateWidget(covariant HomeFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.advertisements, widget.advertisements)) {
      _advertisements.clear();
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
    } catch (_) {
      // SubmissionFeedback already gave the user a concrete error message.
    }
  }

  Future<void> _selectSort() async {
    final selected = await showModalBottomSheet<_HomeSort>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => _SortSheet(current: _sort),
    );
    if (selected == null || selected == _sort || !mounted) return;
    setState(() => _sort = selected);
    await _refresh(successMessage: '排序已更新');
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
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            key: PageStorageKey<String>('home_feed_${widget.key}_$_sort'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: _buildSlivers(),
          ),
        );
      },
    );
  }

  List<Widget> _buildSlivers() {
    final header = <Widget>[
      if (widget.showSort)
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _selectSort,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 12, 10),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: '排序方式：'),
                      TextSpan(
                        text: _sort.label,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      if (widget.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          sliver: SliverToBoxAdapter(
            child: HomeBannerCarousel(items: widget.banners),
          ),
        ),
    ];

    if (_controller.initialLoading && _controller.items.isEmpty) {
      return <Widget>[
        ...header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_controller.error != null && _controller.items.isEmpty) {
      return <Widget>[
        ...header,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _HomeLoadState(
            icon: Icons.cloud_off_outlined,
            message: '内容加载失败',
            actionText: '重新加载',
            onAction: () => _refresh(successMessage: '加载成功'),
          ),
        ),
      ];
    }
    if (_controller.items.isEmpty) {
      return <Widget>[
        ...header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _HomeLoadState(icon: Icons.inbox_outlined, message: '暂无内容'),
        ),
      ];
    }

    final entries = _entries;
    return <Widget>[
      ...header,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
        sliver: SliverList.builder(
          itemCount: _displayUnitCount(entries.length),
          itemBuilder: (context, index) => _buildPostUnit(entries, index),
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

  List<Object> get _entries => buildHomeRecommendationEntries(
    posts: _controller.items,
    advertisements: widget.showSort
        ? widget.advertisements
        : const <BannerItem>[],
    selectAdvertisement: (pageIndex, slot) {
      final key = pageIndex * 2 + slot;
      return _advertisements.putIfAbsent(
        key,
        () =>
            widget.advertisements[_random.nextInt(
              widget.advertisements.length,
            )],
      );
    },
  );

  Widget _buildPostUnit(List<Object> entries, int unitIndex) {
    final block = unitIndex ~/ 5;
    final position = unitIndex % 5;
    final baseIndex = block * 9;
    if (position == 4) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 6),
        child: _buildEntry(entries[baseIndex + 8], large: true),
      );
    }

    final leftIndex = baseIndex + position * 2;
    final rightIndex = leftIndex + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _buildEntry(entries[leftIndex])),
          const SizedBox(width: 6),
          Expanded(
            child: rightIndex < entries.length
                ? _buildEntry(entries[rightIndex])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(Object entry, {bool large = false}) {
    if (entry is BannerItem) {
      return SizedBox(
        height: 168,
        child: HomeGridAdvertisementCard(banner: entry),
      );
    }
    return HomePostCard(post: entry as PostSummary, large: large);
  }

  int _displayUnitCount(int itemCount) {
    final completeBlocks = itemCount ~/ 9;
    final remainder = itemCount % 9;
    return completeBlocks * 5 + (remainder + 1) ~/ 2;
  }
}

enum _HomeSort {
  releaseDate(1, '发布日期'),
  newest(2, '最近更新'),
  hottest(3, '最热作品'),
  mostViewed(4, '最多观看'),
  mostCollected(5, '最多收藏'),
  mostPopular(6, '最受欢迎');

  const _HomeSort(this.value, this.label);

  final int value;
  final String label;
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final _HomeSort current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text('请选择排序方式', style: TextStyle(fontSize: 14)),
          ),
          const Divider(height: 1),
          for (final sort in _HomeSort.values)
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Center(
                child: Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: sort == current
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).pop(sort),
            ),
        ],
      ),
    );
  }
}

class _HomeLoadState extends StatelessWidget {
  const _HomeLoadState({
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 42, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (onAction != null) ...<Widget>[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionText ?? '重试')),
          ],
        ],
      ),
    );
  }
}
