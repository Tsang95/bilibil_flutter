import 'package:flutter/material.dart';

import 'package:b_flutter/api/movie_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/pages/movie/components/movie_post_grid.dart';

final class MovieCategoryArguments {
  const MovieCategoryArguments({
    required this.primaryCategoryId,
    required this.secondaryCategoryId,
    required this.name,
    this.initialSort = 1,
  });

  final int primaryCategoryId;
  final int secondaryCategoryId;
  final String name;
  final int initialSort;
}

class MovieCategoryDetailPage extends StatelessWidget {
  const MovieCategoryDetailPage({super.key, required this.arguments});

  static const _tabs = <String>['最近更新', '强烈推荐', '随机播放', '热门收藏'];

  final MovieCategoryArguments arguments;

  @override
  Widget build(BuildContext context) {
    final initialIndex = arguments.initialSort.clamp(1, 4) - 1;
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: LegacyAppBar(title: arguments.name),
        body: Column(
          children: <Widget>[
            const _MovieSortTabBar(tabs: _tabs),
            Expanded(
              child: TabBarView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  for (var index = 0; index < _tabs.length; index++)
                    MoviePostGrid(
                      storageKey:
                          'movie_category_${arguments.primaryCategoryId}_'
                          '${arguments.secondaryCategoryId}_${index + 1}',
                      loader: (page, forceRefresh) => MovieApi.getPosts(
                        page: page,
                        primaryCategoryId: arguments.primaryCategoryId,
                        secondaryCategoryId: arguments.secondaryCategoryId,
                        sort: index + 1,
                        forceRefresh: forceRefresh,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieSortTabBar extends StatelessWidget {
  const _MovieSortTabBar({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textPrimary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        tabs: <Widget>[for (final tab in tabs) Tab(text: tab)],
      ),
    );
  }
}
