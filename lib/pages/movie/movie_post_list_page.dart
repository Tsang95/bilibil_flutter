import 'package:flutter/material.dart';

import 'package:b_flutter/api/movie_api.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/pages/movie/components/movie_post_grid.dart';

final class MovieSearchArguments {
  const MovieSearchArguments({required this.keyword});

  final String keyword;
}

class MoviePostListPage extends StatelessWidget {
  const MoviePostListPage({super.key, required this.arguments});

  final MovieSearchArguments arguments;

  @override
  Widget build(BuildContext context) {
    final keyword = arguments.keyword;
    return Scaffold(
      appBar: LegacyAppBar(title: keyword),
      body: MoviePostGrid(
        storageKey: 'movie_keyword_$keyword',
        emptyMessage: '该标签下暂无影视内容',
        loader: (page, forceRefresh) => MovieApi.getPosts(
          page: page,
          keyword: keyword,
          forceRefresh: forceRefresh,
        ),
      ),
    );
  }
}
