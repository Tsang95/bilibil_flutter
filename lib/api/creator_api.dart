import 'package:b_flutter/models/creation_topic.dart';
import 'package:b_flutter/models/creator_models.dart';
import 'package:b_flutter/models/creator_publish_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class CreatorApi {
  static Future<CreatorPublishOptions> getPublishOptions({
    bool forceRefresh = false,
  }) => ApiClient().get<CreatorPublishOptions>(
    'api/plateTypes',
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid creator options');
      return CreatorPublishOptions.fromJson(Map<String, dynamic>.from(data));
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
    cacheTags: const <String>{'creator_publish_options'},
  );

  static Future<List<CreatorPublishOption>> getCollections({
    bool forceRefresh = false,
  }) => ApiClient().get<List<CreatorPublishOption>>(
    'api/postCollectionLists',
    parser: (data) => data is List
        ? data
              .whereType<Map>()
              .map(
                (item) => CreatorPublishOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <CreatorPublishOption>[],
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
    cacheTags: const <String>{'creator_collections'},
  );

  static Future<List<CreatorPublishOption>> getTopics({
    bool forceRefresh = false,
  }) => ApiClient().get<List<CreatorPublishOption>>(
    'api/topics',
    parser: (data) => data is List
        ? data
              .whereType<Map>()
              .map(
                (item) => CreatorPublishOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <CreatorPublishOption>[],
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
    cacheTags: const <String>{'creator_topics'},
  );

  static Future<void> publishWork({required Map<String, Object?> data}) =>
      ApiClient().post<void>(
        'api/publishWorks',
        data: data,
        parser: (_) {},
        deduplicate: true,
        invalidateCacheTags: const <String>{
          'creator_dashboard',
          'creator_works',
          'current_user',
        },
      );

  static Future<CreatorDashboard> getDashboard({bool forceRefresh = false}) =>
      ApiClient().get<CreatorDashboard>(
        'api/creatorCentos',
        parser: (data) {
          if (data is! Map) {
            throw const FormatException('Invalid creator dashboard');
          }
          return CreatorDashboard.fromJson(Map<String, dynamic>.from(data));
        },
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
            : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
        cacheTags: const <String>{'creator_dashboard'},
      );

  static Future<PagedResult<CreatorWork>> getWorks({
    required CreatorWorkStatus status,
    required int page,
    bool forceRefresh = false,
  }) => ApiClient().get<PagedResult<CreatorWork>>(
    'api/publishWorkLists',
    data: <String, Object?>{'page': page, 'type': status.value},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid creator works');
      return PagedResult<CreatorWork>.fromJson(
        Map<String, dynamic>.from(data),
        CreatorWork.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'creator_works'},
  );

  static Future<void> deleteWork({required int id}) => ApiClient().post<void>(
    'api/publishWorkRemoves',
    data: <String, Object?>{'id': id},
    parser: (_) {},
    lock: true,
    lockText: '删除中...',
    showErrorToast: true,
    deduplicate: true,
    invalidateCacheTags: const <String>{
      'creator_dashboard',
      'creator_works',
      'current_user',
    },
  );

  static Future<List<CreationTopicGroup>> getCreationTopics({
    bool forceRefresh = false,
  }) => ApiClient().get<List<CreationTopicGroup>>(
    'api/topicLists',
    parser: (data) => data is List
        ? data
              .whereType<Map>()
              .map(
                (item) => CreationTopicGroup.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <CreationTopicGroup>[],
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
    cacheTags: const <String>{'creation_topics'},
  );

  static Future<List<PostSummary>> getCreationSchoolPosts({
    bool forceRefresh = false,
  }) => ApiClient().get<List<PostSummary>>(
    'api/homeRecommends',
    data: const <String, Object?>{
      'page': 1,
      'size': 16,
      'shcool': 1,
      'order_sort': 1,
      'order_sort_type': 1,
    },
    parser: (data) {
      if (data is! Map) return const <PostSummary>[];
      return PagedResult<PostSummary>.fromJson(
        Map<String, dynamic>.from(data),
        PostSummary.fromJson,
      ).items;
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
    cacheTags: const <String>{'creation_school_posts'},
  );
}
