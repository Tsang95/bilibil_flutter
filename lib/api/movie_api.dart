import 'package:b_flutter/models/movie_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class MovieApi {
  static Future<List<MovieKeywordGroup>> getKeywords({
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<MovieKeywordGroup>>(
      'api/videoKeywords',
      data: const <String, Object?>{},
      parser: (data) => _parseList(data, MovieKeywordGroup.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 10))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
      cacheTags: const <String>{'movie_keywords'},
    );
  }

  static Future<PagedResult<PostSummary>> getPosts({
    required int page,
    int primaryCategoryId = 0,
    int secondaryCategoryId = 0,
    int sort = 0,
    String keyword = '',
    String title = '',
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/videoContentLists',
      data: <String, Object?>{
        'title': title,
        'keyword': keyword,
        'plate_one_id': primaryCategoryId,
        'plate_two_id': secondaryCategoryId,
        'sort': sort,
        'page': page,
      },
      parser: (data) => _parsePage(data, PostSummary.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{
        'movie_posts',
        'movie_posts_$primaryCategoryId',
        if (keyword.isNotEmpty) 'movie_keyword_$keyword',
      },
    );
  }

  static Future<PagedResult<MovieActorGroup>> getActors({
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<MovieActorGroup>>(
      'api/authorLists',
      data: <String, Object?>{'page': page},
      parser: (data) => _parsePage(data, MovieActorGroup.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: const <String>{'movie_actors'},
    );
  }

  static Future<PagedResult<PostSummary>> getActorPosts({
    required int actorId,
    required int sort,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/authorMoreLists',
      data: <String, Object?>{'id': actorId, 'type': sort, 'page': page},
      parser: (data) => _parsePage(data, PostSummary.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'movie_actor_$actorId'},
    );
  }

  static PagedResult<T> _parsePage<T>(
    Object? data,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (data is! Map) throw const FormatException('Invalid movie page data');
    return PagedResult<T>.fromJson(Map<String, dynamic>.from(data), parser);
  }

  static List<T> _parseList<T>(
    Object? data,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (data is! List) return <T>[];
    return data
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
