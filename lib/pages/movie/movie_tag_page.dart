import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/movie_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/movie_models.dart';
import 'package:b_flutter/pages/movie/movie_post_list_page.dart';
import 'package:b_flutter/routes/app_routes.dart';

class MovieTagPage extends StatefulWidget {
  const MovieTagPage({super.key});

  @override
  State<MovieTagPage> createState() => _MovieTagPageState();
}

class _MovieTagPageState extends State<MovieTagPage> {
  List<MovieKeywordGroup> _groups = const <MovieKeywordGroup>[];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load(forceRefresh: false));
  }

  Future<void> _load({required bool forceRefresh}) async {
    if (mounted) setState(() => _error = null);
    try {
      final groups = await MovieApi.getKeywords(forceRefresh: forceRefresh);
      if (mounted) setState(() => _groups = groups);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildSearchHeader()),
            ..._buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SizedBox(
      height: 44,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: Get.back<void>,
            child: const Icon(
              CupertinoIcons.xmark_circle,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => Get.toNamed<void>(AppRoutes.search),
              child: Container(
                height: 30,
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.surfaceMuted,
                ),
                child: Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/images/ic_search.svg',
                      width: 14,
                      height: 14,
                    ),
                    const Text(
                      ' 搜索',
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
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_loading && _groups.isEmpty) {
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
              onPressed: () => unawaited(_load(forceRefresh: true)),
              child: const Text('标签加载失败，点击重试'),
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
              '暂无影视标签',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      for (final group in _groups) ...<Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Text(
              group.keyword,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverGrid.builder(
            itemCount: group.children.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 5,
              mainAxisExtent: 20,
            ),
            itemBuilder: (context, index) {
              final keyword = group.children[index].keyword;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.toNamed<void>(
                  AppRoutes.movieSearch,
                  arguments: MovieSearchArguments(keyword: keyword),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    '#$keyword',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8566FF),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    ];
  }
}
