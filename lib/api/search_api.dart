import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/search_user.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class SearchApi {
  static Future<List<HomeCategory>> getCategories({bool forceRefresh = false}) {
    return ApiClient().get<List<HomeCategory>>(
      'api/navigationTypes',
      data: const <String, Object?>{'type': 3},
      parser: (data) => _parseList(data, HomeCategory.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 10))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
      cacheTags: const <String>{'search_categories'},
    );
  }

  static Future<PagedResult<PostSummary>> getRankings({
    required int type,
    required int page,
    bool forceRefresh = false,
  }) {
    return _getPostPage(
      'api/videoRankings',
      data: <String, Object?>{'page': page, 'type': type},
      forceRefresh: forceRefresh,
      cacheTag: 'search_rankings_$type',
    );
  }

  static Future<PagedResult<PostSummary>> searchPosts({
    required String keyword,
    required int categoryId,
    required int page,
    bool forceRefresh = false,
  }) {
    return _getPostPage(
      'api/postContentLists',
      data: <String, Object?>{
        'page': page,
        'plate_one_id': categoryId,
        'plate_two_id': 0,
        'title': keyword,
        'label_id': '',
        'order_sort': 0,
        'size': 0,
        'collection_id': '',
      },
      forceRefresh: forceRefresh,
      cacheTag: 'search_posts',
    );
  }

  static Future<PagedResult<SearchUser>> searchUsers({
    required String keyword,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<SearchUser>>(
      'api/souMembers',
      data: <String, Object?>{'nickname': keyword, 'page': page},
      parser: (data) =>
          PagedResult<SearchUser>.fromJson(_pageMap(data), SearchUser.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'search_users'},
    );
  }

  static Future<void> toggleFollow({required int userId}) {
    return ApiClient().post<void>(
      'api/focusOns',
      data: <String, Object?>{'member_id': userId},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: const <String>{
        'search_users',
        'follow_users',
        'user_detail',
      },
    );
  }

  static Future<PagedResult<PostSummary>> _getPostPage(
    String path, {
    required Map<String, Object?> data,
    required bool forceRefresh,
    required String cacheTag,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      path,
      data: data,
      parser: (value) {
        return PagedResult<PostSummary>.fromJson(
          _pageMap(value),
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{cacheTag},
    );
  }

  static Map<String, dynamic> _pageMap(Object? value) {
    if (value is! Map) throw const FormatException('Invalid page data');
    return Map<String, dynamic>.from(value);
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
