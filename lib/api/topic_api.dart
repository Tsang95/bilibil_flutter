import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class TopicApi {
  static Future<List<TopicSummary>> searchTopics({
    String keyword = '',
    bool forceRefresh = false,
  }) {
    final normalizedKeyword = keyword.trim();
    return ApiClient().get<List<TopicSummary>>(
      'api/topics',
      data: <String, Object?>{'keyword': normalizedKeyword},
      parser: (data) {
        if (data is! List) return <TopicSummary>[];
        return data
            .whereType<Map>()
            .map(
              (item) => TopicSummary.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: <String>{'topics_$normalizedKeyword'},
    );
  }

  static Future<PagedResult<PostSummary>> getTopicPosts({
    required int topicId,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/hotRecommends',
      data: <String, Object?>{'topic_id': topicId, 'page': page},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid topic posts');
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(data),
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'topic_posts_$topicId'},
    );
  }
}
