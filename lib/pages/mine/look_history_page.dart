import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';

typedef HistoryCategoryLoader = Future<List<HomeCategory>> Function();
typedef UserPostRecordLoader = Future<PagedResult<PostSummary>> Function(
  int page,
  int categoryId,
  bool forceRefresh,
);

class LookHistoryPage extends StatefulWidget {
  const LookHistoryPage({
    super.key,
    this.title = '历史记录',
    this.loadCategories,
    this.loadPage,
  });

  final String title;
  final HistoryCategoryLoader? loadCategories;
  final UserPostRecordLoader? loadPage;

  @override
  State<LookHistoryPage> createState() => _LookHistoryPageState();
}

class _LookHistoryPageState extends State<LookHistoryPage> {
  final _sortKey = GlobalKey();
  final _scrollController = ScrollController();
  late final HomeFeedController _controller;
  List<HomeCategory> _categories = const <HomeCategory>[];
  HomeCategory? _selectedCategory;
  Future<void>? _categoryLoadFuture;

  @override
  void initState() {
    super.initState();
    _controller = HomeFeedController((page, forceRefresh) {
      final loader = widget.loadPage;
      if (loader != null) {
        return loader(page, _selectedCategory?.id ?? 0, forceRefresh);
      }
      return UserApi.getViewHistory(
        page: page,
        categoryId: _selectedCategory?.id ?? 0,
        forceRefresh: forceRefresh,
      );
    });
    _scrollController.addListener(_onScroll);
    unawaited(_loadCategories());
    unawaited(_controller.loadInitial().catchError((_) {}));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 360) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _loadCategories() {
    return _categoryLoadFuture ??= _fetchCategories().whenComplete(() {
      _categoryLoadFuture = null;
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final loader =
          widget.loadCategories ?? () => HomeApi.getNavigation(type: 3);
      final categories = await loader();
      if (!mounted) return;
      setState(
        () => _categories = <HomeCategory>[
          const HomeCategory(
            id: 0,
            parentId: 0,
            name: '全部',
            backgroundUrl: '',
            itemCount: 0,
            styleType: 0,
            showModel: 0,
            children: <HomeCategory>[],
          ),
          ...categories,
        ],
      );
    } catch (_) {
      // The history list remains available if the optional filter fails.
    }
  }

  Future<void> _refresh() async {
    try {
      await _controller.refresh();
    } catch (_) {
      // ApiClient has displayed the legacy request error toast.
    }
  }

  Future<void> _selectCategory() async {
    if (_categories.isEmpty) await _loadCategories();
    if (!mounted || _categories.isEmpty) return;
    final renderBox = _sortKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final origin = renderBox.localToGlobal(Offset.zero);
    final result = await showGeneralDialog<HomeCategory>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭板块选择',
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) => Stack(
        children: <Widget>[
          Positioned(
            top: origin.dy + renderBox.size.height,
            left: 0,
            right: 0,
            child: Material(
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(category),
                      child: Container(
                        height: 40,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider,
                              width: .5,
                            ),
                          ),
                        ),
                        child: Text(
                          category.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (result == null || result.id == _selectedCategory?.id || !mounted) {
      return;
    }
    setState(() => _selectedCategory = result.id == 0 ? null : result);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: LegacyAppBar(title: widget.title),
        body: Column(
          children: <Widget>[
            _HistoryCategoryBar(
              key: _sortKey,
              categoryName: _selectedCategory?.name ?? '全部',
              onTap: () => unawaited(_selectCategory()),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: _HistoryList(
                    controller: _controller,
                    scrollController: _scrollController,
                    onRetry: _refresh,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HistoryCategoryBar extends StatelessWidget {
  const _HistoryCategoryBar({
    super.key,
    required this.categoryName,
    required this.onTap,
  });

  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        color: AppColors.surfaceMuted,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            const Text('当前板块：', style: TextStyle(fontSize: 14)),
            const Spacer(),
            InkWell(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    categoryName,
                    style:
                        const TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.controller,
    required this.scrollController,
    required this.onRetry,
  });

  final HomeFeedController controller;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (controller.initialLoading && controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (controller.error != null && controller.items.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(onRetry()),
          child: const Text('加载失败，点击重试'),
        ),
      );
    }
    if (controller.items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(
            height: 240,
            child: Center(
              child: Text(
                '暂无数据',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.items.length + 1,
      itemBuilder: (context, index) {
        if (index == controller.items.length) {
          return _HistoryFooter(
            loading: controller.loadingMore,
            hasMore: controller.hasMore,
          );
        }
        return _HistoryPostCard(post: controller.items[index]);
      },
    );
  }
}

class _HistoryPostCard extends StatelessWidget {
  const _HistoryPostCard({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Get.toNamed<void>(
          AppRoutes.postDetailPath(post.id),
          arguments: AppRoutes.postDetailArguments(post),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 40,
                      child: LegacyNetworkImage(
                        url: post.authorAvatarUrl,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 3),
                          Text(
                            post.authorNickname,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '${_historyTime(post.createdAt)} • 投稿了视频',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(post.title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: LegacyNetworkImage(
                  url: post.preferredCoverUrl,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  if (post.categoryName.isNotEmpty)
                    _HistoryPill(
                      '#${post.categoryName}',
                      backgroundColor: const Color(0xFF8566FF),
                      foregroundColor: Colors.white,
                    ),
                  const Spacer(),
                  if (post.isVipOnly) ...<Widget>[
                    const _HistoryPill(
                      'VIP',
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    const SizedBox(width: 10),
                  ],
                  _HistoryStat(label: '购买：', value: post.salesCount),
                  const SizedBox(width: 10),
                  _HistoryStat(label: '浏览：', value: post.viewCount),
                  const SizedBox(width: 10),
                  _HistoryStat(label: '收藏：', value: post.collectCount),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill(
    this.label, {
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: TextStyle(color: foregroundColor, fontSize: 12),
          ),
        ),
      );
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12),
          children: <InlineSpan>[
            TextSpan(
              text: label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextSpan(text: '$value'),
          ],
        ),
      );
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({required this.loading, required this.hasMore});

  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Center(
          child: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  hasMore ? '' : '已经到底了',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
        ),
      );
}

String _historyTime(DateTime? value) {
  if (value == null) return '';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return '刚刚';
  if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
  if (difference.inDays < 1) return '${difference.inHours}小时前';
  if (difference.inDays < 30) return '${difference.inDays}天前';
  if (difference.inDays < 365) return '${difference.inDays ~/ 30}个月前';
  return '${difference.inDays ~/ 365}年前';
}
