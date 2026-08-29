import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/movie_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/movie_models.dart';
import 'package:b_flutter/pages/movie/components/movie_actor_work_card.dart';
import 'package:b_flutter/pages/movie/movie_actor_detail_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class MovieActorPage extends StatefulWidget {
  const MovieActorPage({super.key});

  @override
  State<MovieActorPage> createState() => _MovieActorPageState();
}

class _MovieActorPageState extends State<MovieActorPage> {
  final ScrollController _scrollController = ScrollController();
  final List<MovieActorGroup> _groups = <MovieActorGroup>[];
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    unawaited(_replace(forceRefresh: false).catchError((_) {}));
  }

  void _handleScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 360) {
      unawaited(_loadMore());
    }
  }

  Future<void> _replace({required bool forceRefresh}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) setState(() => _error = null);
    try {
      final result = await MovieApi.getActors(
        page: 1,
        forceRefresh: forceRefresh,
      );
      _groups
        ..clear()
        ..addAll(result.items);
      _page = result.page == 0 ? 1 : result.page;
      _hasMore = result.hasMore;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _initialLoading = false;
      _refreshing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadMore() async {
    if (_initialLoading || _refreshing || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    if (mounted) setState(() {});
    try {
      final result = await MovieApi.getActors(page: _page + 1);
      final existingIds = _groups.map((item) => item.id).toSet();
      _groups.addAll(
        result.items.where((item) => item.id == 0 || existingIds.add(item.id)),
      );
      _page = result.page == 0 ? _page + 1 : result.page;
      _hasMore = result.hasMore;
    } catch (_) {
      // The existing list remains usable. Pull-to-refresh exposes the failure.
    } finally {
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: () => _replace(forceRefresh: true),
        successMessage: '刷新成功',
        fallbackErrorMessage: '女优内容刷新失败',
        lock: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '女优'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _buildSlivers(),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    if (_initialLoading && _groups.isEmpty) {
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
    if (_error != null && _groups.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: () => unawaited(_refresh()),
              child: const Text('女优内容加载失败，点击重试'),
            ),
          ),
        ),
      ];
    }
    if (_groups.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无女优内容',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      for (final group in _groups) ...<Widget>[
        SliverToBoxAdapter(child: _MovieActorHeader(group: group)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              scrollDirection: Axis.horizontal,
              itemCount: group.works.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  MovieActorWorkCard(work: group.works[index]),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: SizedBox(
          height: 48,
          child: Center(
            child: _loadingMore
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _hasMore ? '' : '已经到底了',
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

class _MovieActorHeader extends StatelessWidget {
  const _MovieActorHeader({required this.group});

  final MovieActorGroup group;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed<void>(
        AppRoutes.movieActorDetail,
        arguments: MovieActorDetailArguments(
          actorId: group.id,
          name: group.name,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${group.name}(作品共${group.workCount}个)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              '更多',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(width: 2),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textTertiary,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
