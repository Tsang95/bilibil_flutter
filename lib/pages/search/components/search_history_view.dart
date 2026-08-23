import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/search_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_feed_controller.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class SearchHistoryView extends StatefulWidget {
  const SearchHistoryView({
    super.key,
    required this.history,
    required this.onSearch,
    required this.onClear,
  });

  final List<String> history;
  final ValueChanged<String> onSearch;
  final Future<void> Function() onClear;

  @override
  State<SearchHistoryView> createState() => _SearchHistoryViewState();
}

class _SearchHistoryViewState extends State<SearchHistoryView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late HomeFeedController _rankController;
  int _rankType = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rankController = _createRankController();
    _scrollController.addListener(_handleScroll);
    unawaited(_rankController.loadInitial().catchError((_) {}));
  }

  HomeFeedController _createRankController() {
    return HomeFeedController(
      (page, forceRefresh) => SearchApi.getRankings(
        type: _rankType,
        page: page,
        forceRefresh: forceRefresh,
      ),
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 420) {
      unawaited(_rankController.loadMore());
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: _rankController.refresh,
        successMessage: '排行榜已刷新',
        fallbackErrorMessage: '排行榜刷新失败',
        lock: false,
      );
    } catch (_) {}
  }

  Future<void> _selectRankType(int type) async {
    if (type == _rankType) return;
    final oldController = _rankController;
    setState(() {
      _rankType = type;
      _rankController = _createRankController();
    });
    oldController.dispose();
    try {
      await SubmissionFeedback.run<void>(
        action: _rankController.loadInitial,
        successMessage: '榜单已更新',
        fallbackErrorMessage: '榜单更新失败',
        lock: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _rankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: _rankController,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            key: const PageStorageKey<String>('search-history'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildHistory()),
              SliverToBoxAdapter(child: _buildRankHeader()),
              ..._buildRankSlivers(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: widget.history.isEmpty
                    ? null
                    : () => unawaited(widget.onClear()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '清空全部',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 15,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.history.isEmpty)
            const Text(
              '没有搜索记录',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.history
                  .map(
                    (keyword) => InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => widget.onSearch(keyword),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          child: Text(
                            keyword,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildRankHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              '搜索排行榜',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          _RankButton(
            text: '畅销榜单',
            selected: _rankType == 1,
            onTap: () => unawaited(_selectRankType(1)),
          ),
          _RankButton(
            text: '热度榜单',
            selected: _rankType == 2,
            onTap: () => unawaited(_selectRankType(2)),
          ),
          _RankButton(
            text: '精品榜单',
            selected: _rankType == 3,
            onTap: () => unawaited(_selectRankType(3)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRankSlivers() {
    if (_rankController.initialLoading && _rankController.items.isEmpty) {
      return const <Widget>[
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ];
    }
    if (_rankController.error != null && _rankController.items.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: _SearchError(
            onRetry: () => unawaited(_refresh()),
            message: '排行榜加载失败',
          ),
        ),
      ];
    }
    if (_rankController.items.isEmpty) {
      return const <Widget>[
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: Center(
              child: Text(
                '暂无排行内容',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        sliver: SliverGrid.builder(
          itemCount: _rankController.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.04,
          ),
          itemBuilder: (context, index) => HomePostCard(
            post: _rankController.items[index],
            fillHeight: true,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 42,
          child: Center(
            child: _rankController.loadingMore
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _rankController.hasMore ? '' : '已经到底了',
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

class _RankButton extends StatelessWidget {
  const _RankButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 6, 0, 6),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}
