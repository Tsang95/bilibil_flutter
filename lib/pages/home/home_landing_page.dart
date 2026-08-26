import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/pages/home/components/home_feed_tab.dart';
import 'package:b_flutter/pages/home/home_category_tab.dart';
import 'package:b_flutter/pages/home/home_forum_tab.dart';
import 'package:b_flutter/pages/home/home_latest_tab.dart';
import 'package:b_flutter/pages/home/home_movie_tab.dart';
import 'package:b_flutter/pages/home/home_top_menu_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/logger_util.dart';

@visibleForTesting
List<BannerItem> selectHomeListAdvertisements(List<BannerItem> items) =>
    items.where((item) => item.category == 4).toList(growable: false);

class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({
    super.key,
    required this.onOpenMessage,
    required this.onOpenMine,
  });

  final VoidCallback onOpenMessage;
  final VoidCallback onOpenMine;

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> {
  List<HomeCategory> _categories = const <HomeCategory>[];
  List<BannerItem> _banners = const <BannerItem>[];
  List<BannerItem> _contentAds = const <BannerItem>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadChrome());
  }

  Future<void> _loadChrome() async {
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        _loadOr<List<HomeCategory>>(
          HomeApi.getNavigation(),
          _categories,
          '首页频道',
        ),
        _loadOr<List<BannerItem>>(HomeApi.getTopBanners(), _banners, '首页轮播'),
        _loadOr<List<BannerItem>>(
          HomeApi.getContentBanners(),
          _contentAds,
          '首页内容广告',
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = values[0] as List<HomeCategory>;
        _banners = values[1] as List<BannerItem>;
        _contentAds = selectHomeListAdvertisements(
          values[2] as List<BannerItem>,
        );
      });
    } catch (error, stackTrace) {
      logger.w('首页频道或轮播加载失败', error: error, stackTrace: stackTrace);
    }
  }

  Future<T> _loadOr<T>(Future<T> request, T fallback, String label) async {
    try {
      return await request;
    } catch (error, stackTrace) {
      logger.w('$label加载失败', error: error, stackTrace: stackTrace);
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <_HomeTabDefinition>[
      _HomeTabDefinition(
        id: 'popular',
        label: '热门',
        page: HomeFeedTab(
          key: const ValueKey<String>('home_popular'),
          showSort: true,
          banners: _banners,
          advertisements: _contentAds,
          loader: (page, forceRefresh, sortType) => HomeApi.getRecommendations(
            page: page,
            sortType: sortType,
            forceRefresh: forceRefresh,
          ),
        ),
      ),
      const _HomeTabDefinition(
        id: 'latest',
        label: '最新',
        page: HomeLatestTab(key: ValueKey<String>('home_latest')),
      ),
      for (final category in _categories)
        _HomeTabDefinition(
          id: 'category_${category.id}',
          label: category.name,
          page: _buildCategoryPage(category),
        ),
    ];

    return DefaultTabController(
      key: ValueKey<String>(tabs.map((tab) => tab.id).join('|')),
      length: tabs.length,
      child: ColoredBox(
        color: AppColors.surfaceMuted,
        child: Column(
          children: <Widget>[
            _HomeSearchHeader(
              onOpenMessage: widget.onOpenMessage,
              onOpenMine: widget.onOpenMine,
            ),
            ColoredBox(
              color: AppColors.surface,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 2,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textPrimary,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 14),
                        tabs: <Widget>[
                          for (final tab in tabs) Tab(text: tab.label),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _openAllChannels,
                      child: SizedBox.square(
                        dimension: 40,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/ic_home_menu.svg',
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 0.5),
            Expanded(
              child: TabBarView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[for (final tab in tabs) tab.page],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPage(HomeCategory category) {
    final key = ValueKey<String>('home_category_${category.id}');
    return switch (category.id) {
      83 => HomeForumTab(
        key: key,
        category: category,
        banners: _banners,
        contentAds: _contentAds,
      ),
      19 => HomeMovieTab(key: key, category: category, banners: _banners),
      _ => HomeCategoryTab(
        key: key,
        category: category,
        banners: _banners,
        contentAds: _contentAds,
      ),
    };
  }

  void _openAllChannels() {
    Get.toNamed<void>(
      AppRoutes.homeTopMenu,
      arguments: HomeTopMenuArguments(
        categories: _categories,
        banners: _banners,
        contentAds: _contentAds,
      ),
    );
  }
}

class _HomeSearchHeader extends StatelessWidget {
  const _HomeSearchHeader({
    required this.onOpenMessage,
    required this.onOpenMine,
  });

  final VoidCallback onOpenMessage;
  final VoidCallback onOpenMine;

  @override
  Widget build(BuildContext context) {
    final userStore = Get.find<UserStore>();
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  'assets/images/ic_app_logo_h.svg',
                  width: 70,
                  height: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => Get.toNamed<void>(AppRoutes.search),
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: <Widget>[
                          SvgPicture.asset(
                            'assets/images/ic_search.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            '搜索',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final avatarUrl = userStore.user.value?.avatarUrl ?? '';
                  return GestureDetector(
                    onTap: onOpenMine,
                    child: SizedBox.square(
                      dimension: 28,
                      child: avatarUrl.isEmpty
                          ? Image.asset(
                              'assets/images/bg_home_user.png',
                              fit: BoxFit.cover,
                            )
                          : LegacyNetworkImage(
                              url: avatarUrl,
                              borderRadius: BorderRadius.circular(50),
                            ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                Obx(() {
                  final count = userStore.user.value?.commentMessageCount ?? 0;
                  return GestureDetector(
                    onTap: onOpenMessage,
                    child: SizedBox(
                      width: 24,
                      height: 28,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/ic_email.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: -3,
                              top: 0,
                              child: _MessageBadge(count: count),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBadge extends StatelessWidget {
  const _MessageBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 8),
        ),
      ),
    );
  }
}

final class _HomeTabDefinition {
  const _HomeTabDefinition({
    required this.id,
    required this.label,
    required this.page,
  });

  final String id;
  final String label;
  final Widget page;
}
