import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/creator_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/creator_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

typedef CreatorWorksLoader =
    Future<PagedResult<CreatorWork>> Function({
      required CreatorWorkStatus status,
      required int page,
      bool forceRefresh,
    });
typedef CreatorWorkDelete = Future<void> Function({required int id});

class CreatorHistoryPage extends StatefulWidget {
  const CreatorHistoryPage({
    super.key,
    this.initialIndex = 0,
    this.loader,
    this.deleteWork,
  });

  final int initialIndex;
  final CreatorWorksLoader? loader;
  final CreatorWorkDelete? deleteWork;

  @override
  State<CreatorHistoryPage> createState() => _CreatorHistoryPageState();
}

class _CreatorHistoryPageState extends State<CreatorHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CreatorWorkStatus.values.length,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '我的作品'),
    body: Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textPrimary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          dividerColor: AppColors.divider,
          tabs: CreatorWorkStatus.values
              .map((status) => Tab(text: status.label))
              .toList(growable: false),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: CreatorWorkStatus.values
                .map(
                  (status) => _CreatorWorkList(
                    key: PageStorageKey<String>(
                      'creator_works_${status.value}',
                    ),
                    status: status,
                    loader: widget.loader ?? CreatorApi.getWorks,
                    deleteWork: widget.deleteWork ?? CreatorApi.deleteWork,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    ),
  );
}

class _CreatorWorkList extends StatefulWidget {
  const _CreatorWorkList({
    super.key,
    required this.status,
    required this.loader,
    required this.deleteWork,
  });

  final CreatorWorkStatus status;
  final CreatorWorksLoader loader;
  final CreatorWorkDelete deleteWork;

  @override
  State<_CreatorWorkList> createState() => _CreatorWorkListState();
}

class _CreatorWorkListState extends State<_CreatorWorkList>
    with AutomaticKeepAliveClientMixin<_CreatorWorkList> {
  final ScrollController _scrollController = ScrollController();
  List<CreatorWork> _works = const <CreatorWork>[];
  final Set<int> _deleting = <int>{};
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore || (!refresh && (!_hasMore || _loading))) return;
    final page = refresh ? 1 : _page + 1;
    setState(() {
      if (refresh) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await widget.loader(
        status: widget.status,
        page: page,
        forceRefresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _works = refresh
            ? result.items
            : <CreatorWork>[..._works, ...result.items];
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _delete(CreatorWork work) async {
    if (_deleting.contains(work.id)) return;
    setState(() => _deleting.add(work.id));
    try {
      await widget.deleteWork(id: work.id);
      if (!mounted) return;
      showToast('删除成功', type: ToastType.success);
      await _load(refresh: true);
    } catch (_) {
      if (mounted) showToast('删除失败，请稍后重试', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _deleting.remove(work.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _works.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => _load(refresh: true),
          child: const Text('加载失败，点击重试'),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _works.length + 1,
        itemBuilder: (context, index) {
          if (index == _works.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  _works.isEmpty
                      ? '暂无数据'
                      : _hasMore
                      ? ''
                      : '没有更多了',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          final work = _works[index];
          return _CreatorWorkCard(
            work: work,
            status: widget.status,
            deleting: _deleting.contains(work.id),
            onDelete: () => _delete(work),
          );
        },
      ),
    );
  }
}

class _CreatorWorkCard extends StatelessWidget {
  const _CreatorWorkCard({
    required this.work,
    required this.status,
    required this.deleting,
    required this.onDelete,
  });

  final CreatorWork work;
  final CreatorWorkStatus status;
  final bool deleting;
  final VoidCallback onDelete;

  Color get _statusColor => switch (status) {
    CreatorWorkStatus.published => AppColors.primary,
    CreatorWorkStatus.reviewing => Colors.blueAccent,
    CreatorWorkStatus.rejected => Colors.redAccent,
  };

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: work.id <= 0
        ? null
        : () => Get.toNamed<void>(AppRoutes.postDetailPath(work.id)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(work.title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: LegacyNetworkImage(
              url: work.preferredCoverUrl,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              if (work.categoryName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8566FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${work.categoryName}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              const Spacer(),
              if (work.vipOnly) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              _metric('购买：', work.salesCount),
              const SizedBox(width: 10),
              _metric('浏览：', work.viewsCount),
              const SizedBox(width: 10),
              _metric('收藏：', work.collectCount),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 24,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${status.label}${work.reason.isEmpty ? '' : ':${work.reason}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _statusColor),
                  ),
                ),
                InkWell(
                  key: ValueKey<String>('delete_creator_work_${work.id}'),
                  onTap: deleting ? null : onDelete,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          deleting ? '删除中' : '删除帖子',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.trash,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: .5, thickness: .5),
        ],
      ),
    ),
  );

  Widget _metric(String label, int value) => Text.rich(
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
