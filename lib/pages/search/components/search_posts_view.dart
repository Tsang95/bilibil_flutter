import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/search_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class SearchPostsView extends StatefulWidget {
  const SearchPostsView({super.key, required this.keyword});

  final String keyword;

  @override
  State<SearchPostsView> createState() => _SearchPostsViewState();
}

class _SearchPostsViewState extends State<SearchPostsView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late HomeFeedController _controller;
  List<HomeCategory> _categories = const <HomeCategory>[];
  HomeCategory? _selectedCategory;
  bool _loadingCategories = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _scrollController.addListener(_handleScroll);
    unawaited(_controller.loadInitial().catchError((_) {}));
    unawaited(_loadCategories());
  }

  HomeFeedController _createController() {
    return HomeFeedController(
      (page, forceRefresh) => SearchApi.searchPosts(
        keyword: widget.keyword,
        categoryId: _selectedCategory?.id ?? 0,
        page: page,
        forceRefresh: forceRefresh,
      ),
    );
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    if (_loadingCategories) return;
    _loadingCategories = true;
    try {
      final categories = await SearchApi.getCategories(
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // The default "全部" filter remains usable when category metadata fails.
    } finally {
      _loadingCategories = false;
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: _controller.refresh,
        successMessage: '搜索结果已刷新',
        fallbackErrorMessage: '搜索结果刷新失败',
        lock: false,
      );
    } catch (_) {}
  }

  Future<void> _openCategoryPicker() async {
    if (_categories.isEmpty) await _loadCategories(forceRefresh: true);
    if (!mounted) return;
    final selection = await showModalBottomSheet<_CategorySelection>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    '选择板块',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      final category =
                          index == 0 ? null : _categories[index - 1];
                      final selected = category?.id == _selectedCategory?.id;
                      return ListTile(
                        dense: true,
                        title: Text(category?.name ?? '全部'),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_CategorySelection(category)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;

    if (selection == null) return;
    final selected = selection.category;
    if (selected?.id != _selectedCategory?.id) await _changeCategory(selected);
  }

  Future<void> _changeCategory(HomeCategory? category) async {
    final oldController = _controller;
    setState(() {
      _selectedCategory = category;
      _controller = _createController();
    });
    oldController.dispose();
    try {
      await SubmissionFeedback.run<void>(
        action: _controller.loadInitial,
        successMessage: '板块已更新',
        fallbackErrorMessage: '板块更新失败',
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
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            key: PageStorageKey<String>('search-posts-${widget.keyword}'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildFilter()),
              ..._buildResultSlivers(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilter() {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            const Text(
              '当前板块：',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Spacer(),
            InkWell(
              onTap: () => unawaited(_openCategoryPicker()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      _selectedCategory?.name ?? '全部',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultSlivers() {
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
          child: _SearchResultMessage(
            message: '搜索结果加载失败',
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
          child: _SearchResultMessage(message: '没有找到相关帖子'),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        sliver: SliverGrid.builder(
          itemCount: _controller.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.04,
          ),
          itemBuilder: (context, index) =>
              HomePostCard(post: _controller.items[index]),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 42,
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

class _SearchResultMessage extends StatelessWidget {
  const _SearchResultMessage({
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

final class _CategorySelection {
  const _CategorySelection(this.category);

  final HomeCategory? category;
}
