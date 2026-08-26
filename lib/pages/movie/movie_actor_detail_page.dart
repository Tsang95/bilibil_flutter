import 'package:flutter/material.dart';

import 'package:b_flutter/api/movie_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/pages/movie/components/movie_post_grid.dart';

final class MovieActorDetailArguments {
  const MovieActorDetailArguments({
    required this.actorId,
    required this.name,
    this.initialSort = 1,
  });

  final int actorId;
  final String name;
  final int initialSort;
}

class MovieActorDetailPage extends StatelessWidget {
  const MovieActorDetailPage({super.key, required this.arguments});

  static const _tabs = <String>['最近更新', '强烈推荐', '随机播放', '热门收藏'];

  final MovieActorDetailArguments arguments;

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
            Container(
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
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: <Widget>[for (final tab in _tabs) Tab(text: tab)],
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  for (var index = 0; index < _tabs.length; index++)
                    MoviePostGrid(
                      storageKey:
                          'movie_actor_${arguments.actorId}_${index + 1}',
                      loader: (page, forceRefresh) => MovieApi.getActorPosts(
                        actorId: arguments.actorId,
                        sort: index + 1,
                        page: page,
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
