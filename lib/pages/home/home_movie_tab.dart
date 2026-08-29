import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_movie_post_card.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class HomeMovieTab extends StatefulWidget {
  const HomeMovieTab({
    super.key,
    required this.category,
    required this.banners,
    this.bannerLoading = false,
  });

  final HomeCategory category;
  final List<BannerItem> banners;
  final bool bannerLoading;

  @override
  State<HomeMovieTab> createState() => _HomeMovieTabState();
}

class _HomeMovieTabState extends State<HomeMovieTab>
    with AutomaticKeepAliveClientMixin<HomeMovieTab> {
  List<_MovieSectionData> _sections = const <_MovieSectionData>[];
  bool _loading = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load(forceRefresh: false).catchError((_) {}));
  }

  Future<void> _load({required bool forceRefresh}) async {
    if (mounted) {
      setState(() {
        _error = null;
        if (_sections.isEmpty) _loading = true;
      });
    }
    try {
      final categories = await HomeApi.getMovieSections(
        categoryId: widget.category.id,
        forceRefresh: forceRefresh,
      );
      final sections = await Future.wait<_MovieSectionData>(
        categories.map((category) async {
          final page = await HomeApi.getCategoryPosts(
            categoryId:
                category.parentId == 0 ? widget.category.id : category.parentId,
            childCategoryId: category.id,
            page: 1,
            size: 5,
            forceRefresh: forceRefresh,
          );
          return _MovieSectionData(category: category, posts: page.items);
        }),
      );
      if (!mounted) return;
      setState(() => _sections = sections);
    } catch (error) {
      if (mounted) setState(() => _error = error);
      rethrow;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      await SubmissionFeedback.run<void>(
        action: () => _load(forceRefresh: true),
        successMessage: '刷新成功',
        fallbackErrorMessage: '刷新失败，请稍后重试',
        lock: false,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(
        key: PageStorageKey<String>('home_movie_${widget.category.id}'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: _buildSlivers(),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[
      if (widget.bannerLoading || widget.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: widget.bannerLoading && widget.banners.isEmpty
                ? const HomeBannerSkeleton(
                    key: ValueKey<String>('home_banner_skeleton'),
                  )
                : HomeBannerCarousel(items: widget.banners),
          ),
        ),
    ];
    if (_loading && _sections.isEmpty) {
      return <Widget>[
        ...slivers,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_error != null && _sections.isEmpty) {
      return <Widget>[
        ...slivers,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('影视内容加载失败，点击重试'),
            ),
          ),
        ),
      ];
    }
    if (_sections.isEmpty) {
      return <Widget>[
        ...slivers,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无影视内容',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      ];
    }

    for (var sectionIndex = 0;
        sectionIndex < _sections.length;
        sectionIndex++) {
      final section = _sections[sectionIndex];
      slivers.add(_MovieSectionHeader(category: section.category));
      if (section.posts.isEmpty) continue;
      if (sectionIndex == 0) {
        slivers.add(
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                scrollDirection: Axis.horizontal,
                itemCount: section.posts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 5),
                itemBuilder: (context, index) => SizedBox(
                  width: 110,
                  child: HomeMoviePostCard(
                    post: section.posts[index],
                    imageHeight: 146,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverToBoxAdapter(
              child: HomeMoviePostCard(
                post: section.posts.first,
                imageHeight: 200,
              ),
            ),
          ),
        );
        if (section.posts.length > 1) {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              sliver: SliverGrid.builder(
                itemCount: section.posts.length - 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (context, index) => HomeMoviePostCard(
                  post: section.posts[index + 1],
                  imageHeight: 98,
                ),
              ),
            ),
          );
        }
      }
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 10)));
    }
    return slivers;
  }
}

class _MovieSectionHeader extends StatelessWidget {
  const _MovieSectionHeader({required this.category});

  final HomeCategory category;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Row(
              children: <Widget>[
                Text(
                  '查看更多',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _MovieSectionData {
  const _MovieSectionData({required this.category, required this.posts});

  final HomeCategory category;
  final List<PostSummary> posts;
}
