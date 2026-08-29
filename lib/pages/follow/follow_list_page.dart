import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/follow_user.dart';
import 'package:b_flutter/pages/follow/follow_list_controller.dart';
import 'package:b_flutter/utils/toast.dart';

class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final FollowListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FollowListController();
    _scrollController.addListener(_handleScroll);
    unawaited(_loadInitial());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      await _controller.loadInitial();
    } catch (_) {
      // The retry state below exposes a recoverable failure.
    }
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 240) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _search() async {
    try {
      await _controller.search(_searchController.text);
    } catch (_) {
      showToast('搜索失败，请稍后重试', type: ToastType.error);
    }
  }

  Future<void> _cancelSearch() async {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    await _search();
  }

  Future<void> _selectSort() async {
    final screenSize = MediaQuery.sizeOf(context);
    final result = await showMenu<FollowListSort>(
      context: context,
      position: RelativeRect.fromLTRB(screenSize.width - 144, 137, 10, 0),
      items: FollowListSort.values
          .map(
            (sort) => PopupMenuItem<FollowListSort>(
              value: sort == _controller.sort ? null : sort,
              height: 40,
              child: Row(
                children: <Widget>[
                  Text(
                    sort.label,
                    style: TextStyle(
                      color: sort == _controller.sort
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (sort == _controller.sort)
                    const Icon(Icons.check, color: AppColors.primary, size: 14),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
    if (result == null) return;
    try {
      await _controller.changeSort(result);
    } catch (_) {
      showToast('排序更新失败，请稍后重试', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '我的关注'),
        body: Column(
          children: <Widget>[
            _SearchBar(
              controller: _searchController,
              onSubmitted: (_) => unawaited(_search()),
              onCancel: () => unawaited(_cancelSearch()),
            ),
            const Divider(height: .5, color: AppColors.divider),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _SortBar(
                sort: _controller.sort,
                onTap: () => unawaited(_selectSort()),
              ),
            ),
            const Divider(height: .5, color: AppColors.divider),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _buildList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildList() {
    final users = _controller.items;
    if (_controller.initialLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_controller.error != null && users.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(_loadInitial()),
          child: const Text('加载失败，点击重试'),
        ),
      );
    }
    if (users.isEmpty && _controller.keyword.isNotEmpty) {
      return const _EmptySearch();
    }
    if (users.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _search,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: users.length + 1,
        itemBuilder: (context, index) => index == users.length
            ? _Footer(
                loading: _controller.loadingMore,
                hasMore: _controller.hasMore,
                onTap: () => unawaited(_controller.loadMore()),
              )
            : _FollowUserTile(user: users[index]),
        separatorBuilder: (_, index) => index == users.length - 1
            ? const SizedBox.shrink()
            : const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Divider(height: .5, color: AppColors.divider),
              ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onCancel,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/images/ic_search.svg',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          textInputAction: TextInputAction.search,
                          onSubmitted: onSubmitted,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: '搜索我的关注',
                            hintStyle: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 54,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('取消', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onTap});
  final FollowListSort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              const Text(
                '排序方式',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              InkWell(
                onTap: onTap,
                child: Row(
                  children: <Widget>[
                    Text(sort.label, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 5),
                    const Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({required this.user});
  final FollowUser user;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 69,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 48,
                height: 48,
                child: LegacyNetworkImage(
                  url: user.avatarUrl,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 140),
            Image.asset(
              'assets/images/ic_empty_search.png',
              width: 120,
              height: 102,
            ),
            const SizedBox(height: 20),
            const Text(
              '没有搜到相关用户，请尝试别的搜索词',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.hasMore,
    required this.onTap,
  });
  final bool loading;
  final bool hasMore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: loading || !hasMore ? 36 : 0,
        child: Center(
          child: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : hasMore
                  ? null
                  : TextButton(
                      onPressed: onTap,
                      child: const Text(
                        '没有更多了',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ),
        ),
      );
}
