import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/home_content_section.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/home/components/home_portrait_post_card.dart';
import 'package:b_flutter/pages/home/components/home_post_card.dart';
import 'package:b_flutter/pages/home/home_advertisement_action.dart';
import 'package:b_flutter/pages/home/home_more_posts_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

class HomeCategoryTab extends StatefulWidget {
  const HomeCategoryTab({
    super.key,
    required this.category,
    required this.banners,
    required this.contentAds,
  });

  final HomeCategory category;
  final List<BannerItem> banners;
  final List<BannerItem> contentAds;

  @override
  State<HomeCategoryTab> createState() => _HomeCategoryTabState();
}

class _HomeCategoryTabState extends State<HomeCategoryTab>
    with AutomaticKeepAliveClientMixin<HomeCategoryTab> {
  List<HomeContentSection> _sections = const <HomeContentSection>[];
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
      final sections = await HomeApi.getCategorySections(
        categoryId: widget.category.id,
        forceRefresh: forceRefresh,
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
        key: PageStorageKey<String>('home_category_${widget.category.id}'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: _buildSlivers(),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    final result = <Widget>[
      if (widget.banners.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: HomeBannerCarousel(items: widget.banners),
          ),
        ),
    ];
    if (_loading && _sections.isEmpty) {
      return <Widget>[
        ...result,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_error != null && _sections.isEmpty) {
      return <Widget>[
        ...result,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CategoryEmptyState(
            message: '频道内容加载失败',
            actionText: '重新加载',
            onAction: _refresh,
          ),
        ),
      ];
    }
    if (_sections.isEmpty) {
      return <Widget>[
        ...result,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _CategoryEmptyState(message: '暂无频道内容'),
        ),
      ];
    }

    for (
      var sectionIndex = 0;
      sectionIndex < _sections.length;
      sectionIndex++
    ) {
      final section = _sections[sectionIndex];
      result.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    section.category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.toNamed<void>(
                    AppRoutes.homeMorePosts,
                    arguments: HomeMorePostsArguments(
                      parent: widget.category,
                      category: section.category,
                      banners: widget.banners,
                      contentAds: widget.contentAds,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '更多',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final portrait = widget.category.id == 6;
      final ad = !portrait && widget.contentAds.isNotEmpty
          ? widget.contentAds[sectionIndex % widget.contentAds.length]
          : null;
      result.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          sliver: SliverGrid.builder(
            itemCount: section.items.length + (ad == null ? 0 : 1),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: portrait ? 3 : 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              mainAxisExtent: portrait ? 228 : null,
              childAspectRatio: portrait ? 115 / 228 : 175 / 177,
            ),
            itemBuilder: (context, index) {
              if (index >= section.items.length) {
                return _CategoryAdCard(banner: ad!);
              }
              final post = section.items[index];
              return portrait
                  ? HomePortraitPostCard(post: post)
                  : HomePostCard(post: post, fillHeight: true);
            },
          ),
        ),
      );
      result.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));
    }
    return result;
  }
}

class _CategoryAdCard extends StatelessWidget {
  const _CategoryAdCard({required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHomeAdvertisement(banner),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: LegacyNetworkImage(
                url: banner.pictureUrl,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(7),
              child: Text(
                banner.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(7, 0, 7, 7),
              child: Text(
                '#广告',
                style: TextStyle(color: Color(0xFF8566FF), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState({
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
          const Icon(
            Icons.inbox_outlined,
            size: 42,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (onAction != null) ...<Widget>[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionText ?? '重试')),
          ],
        ],
      ),
    );
  }
}
