import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/common_barrage.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_comment.dart';
import 'package:b_flutter/models/post_barrage.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/user_profile.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class PostApi {
  static Future<UserProfile> getUserProfile({
    required int userId,
    bool forceRefresh = false,
  }) => ApiClient().get<UserProfile>(
    'api/ownContentMemberDetails',
    data: <String, Object?>{'member_id': userId},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid user profile');
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: <String>{'user_profile_$userId'},
  );

  static Future<UserProfileHighlights> getUserProfileHighlights({
    required int userId,
    bool forceRefresh = false,
  }) => ApiClient().get<UserProfileHighlights>(
    'api/ownContentVariousLists',
    data: <String, Object?>{'member_id': userId},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid user highlights');
      return UserProfileHighlights.fromJson(Map<String, dynamic>.from(data));
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: <String>{'user_profile_highlights_$userId'},
  );

  static Future<PagedResult<PostSummary>> getUserDynamics({
    required int userId,
    required int page,
    bool forceRefresh = false,
  }) => _getUserPosts(
    path: 'api/ownContentDynamics',
    userId: userId,
    page: page,
    forceRefresh: forceRefresh,
    cacheTag: 'user_dynamics_$userId',
  );

  static Future<PagedResult<PostSummary>> getUserManuscripts({
    required int userId,
    required int page,
    bool forceRefresh = false,
  }) => _getUserPosts(
    path: 'api/ownContentManuscripts',
    userId: userId,
    page: page,
    forceRefresh: forceRefresh,
    cacheTag: 'user_manuscripts_$userId',
    extraData: const <String, Object?>{'sort': 1},
  );

  static Future<PagedResult<PostSummary>> _getUserPosts({
    required String path,
    required int userId,
    required int page,
    required bool forceRefresh,
    required String cacheTag,
    Map<String, Object?> extraData = const <String, Object?>{},
  }) => ApiClient().get<PagedResult<PostSummary>>(
    path,
    data: <String, Object?>{'member_id': userId, 'page': page, ...extraData},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid user post page');
      return PagedResult<PostSummary>.fromJson(
        Map<String, dynamic>.from(data),
        PostSummary.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: <String>{cacheTag},
  );

  static Future<List<CommonBarrage>> getCommonBarrages() {
    return ApiClient().get<List<CommonBarrage>>(
      'api/barrageCommonLists',
      parser: (data) {
        if (data is! List) {
          throw const FormatException('Invalid common barrage list');
        }
        return data
            .whereType<Map>()
            .map(
              (item) => CommonBarrage.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.content.isNotEmpty)
            .toList(growable: false);
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
      cacheTags: const <String>{'common_barrages'},
    );
  }

  static Future<List<PostSummary>> getRecommendations({
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<PostSummary>>(
      'api/newRecommends',
      data: <String, Object?>{'page': 1, 'plate_one_id': categoryId},
      parser: (data) {
        if (data is! Map) {
          throw const FormatException('Invalid recommendation page');
        }
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(data),
          PostSummary.fromJson,
        ).items;
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: const <String>{'post_recommendations'},
    );
  }

  static Future<PagedResult<PostSummary>> getEpisodes({
    required int postId,
    required int page,
    int size = 10,
    int sort = 0,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/selectContentLists',
      data: <String, Object?>{
        'collection_id': postId,
        'page': page,
        'size': size,
        'sort': sort,
      },
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid episode page');
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(data),
          PostSummary.fromJson,
        );
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: <String>{'post_episodes_$postId'},
    );
  }

  static Future<PagedResult<PostSummary>> getPostsByLabel({
    required int labelId,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/postContentLists',
      data: <String, Object?>{
        'page': page,
        'plate_one_id': 0,
        'plate_two_id': 0,
        'title': '',
        'label_id': labelId,
        'order_sort': 1,
        'size': 20,
        'collection_id': '',
      },
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid label posts');
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(data),
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'post_label_$labelId'},
    );
  }

  static Future<List<PostRewardProduct>> getRewardProducts() {
    return ApiClient().get<List<PostRewardProduct>>(
      'api/tipCoinGoods',
      parser: (data) {
        if (data is! List) {
          throw const FormatException('Invalid reward products');
        }
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  PostRewardProduct.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id > 0)
            .toList(growable: false);
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
      cacheTags: const <String>{'post_reward_products'},
      lock: true,
      lockText: '正在加载打赏选项...',
    );
  }

  static Future<List<PostFeedbackReason>> getFeedbackReasons() {
    return ApiClient().get<List<PostFeedbackReason>>(
      'api/questionLists',
      parser: (data) {
        if (data is! List) {
          throw const FormatException('Invalid feedback reasons');
        }
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  PostFeedbackReason.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id > 0 && item.content.isNotEmpty)
            .toList(growable: false);
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
      cacheTags: const <String>{'post_feedback_reasons'},
      lock: true,
      lockText: '正在加载反馈原因...',
    );
  }

  static Future<PagedResult<PostBarrage>> getBarrages({
    required int postId,
    int page = 1,
  }) {
    return ApiClient().get<PagedResult<PostBarrage>>(
      'api/barrageLists',
      data: <String, Object?>{
        'page': page,
        'size': 100,
        'post_content_id': postId,
      },
      parser: (data) {
        if (data is List) {
          return PagedResult<PostBarrage>(
            page: page,
            totalPages: page,
            totalItems: data.length,
            isLastPage: true,
            items: data
                .whereType<Map>()
                .map(
                  (item) =>
                      PostBarrage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false),
          );
        }
        if (data is! Map) throw const FormatException('Invalid barrage page');
        return PagedResult<PostBarrage>.fromJson(
          Map<String, dynamic>.from(data),
          PostBarrage.fromJson,
        );
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: <String>{'post_barrages_$postId'},
    );
  }

  static Future<void> sendBarrage({
    required int postId,
    required String content,
    required Duration playTime,
  }) {
    return ApiClient().post<void>(
      'api/sendBarrages',
      data: <String, Object?>{
        'post_content_id': postId,
        'content': content,
        'play_time': playTime.inSeconds,
      },
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{'post_barrages_$postId'},
    );
  }

  static Future<PostDetail> getDetail({
    required int postId,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PostDetail>(
      'api/postContentDetails',
      data: <String, Object?>{'id': postId},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid post detail');
        return PostDetail.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: <String>{'post_detail_$postId'},
    );
  }

  static Future<List<BannerItem>> getDetailAdvertisements({
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<BannerItem>>(
      'api/bannerAdsBanners',
      data: const <String, Object?>{},
      parser: (data) {
        if (data is! List) {
          throw const FormatException('Invalid detail advertisements');
        }
        return data
            .whereType<Map>()
            .map((item) => BannerItem.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.pictureUrl.trim().isNotEmpty)
            .toList(growable: false);
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 3))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 3)),
      cacheTags: const <String>{'post_detail_advertisements'},
    );
  }

  static Future<void> recordAdvertisementClick(int advertisementOrderId) {
    if (advertisementOrderId <= 0) return Future<void>.value();
    return ApiClient().post<void>(
      'api/deliveryAdvertiseSums',
      data: <String, Object?>{'id': advertisementOrderId},
      parser: (_) {},
      deduplicate: true,
    );
  }

  static Future<void> toggleLike({required int postId}) {
    return _postAction(
      'api/postLikes',
      data: <String, Object?>{'post_id': postId},
      postId: postId,
    );
  }

  static Future<PagedResult<PostComment>> getComments({
    required int postId,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostComment>>(
      'api/postContentCommentLists',
      data: <String, Object?>{'page': page, 'post_id': postId},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid comments page');
        return PagedResult<PostComment>.fromJson(
          Map<String, dynamic>.from(data),
          PostComment.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 20))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 20)),
      cacheTags: <String>{'post_comments_$postId'},
    );
  }

  static Future<void> sendComment({
    required int postId,
    required String content,
  }) {
    return ApiClient().post<void>(
      'api/comments',
      data: <String, Object?>{'post_id': postId, 'content': content},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{'post_comments_$postId'},
    );
  }

  static Future<void> sendReply({
    required int postId,
    required int commentId,
    required String content,
  }) {
    return ApiClient().post<void>(
      'api/commentsReplies',
      data: <String, Object?>{'comment_id': commentId, 'content': content},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{'post_comments_$postId'},
    );
  }

  static Future<void> toggleCollect({required int postId}) {
    return _postAction(
      'api/postCollects',
      data: <String, Object?>{'post_id': postId},
      postId: postId,
    );
  }

  static Future<void> tipCoin({required int postId, required int count}) {
    return _postAction(
      'api/tipsCoins',
      data: <String, Object?>{'post_content_id': postId, 'coin_num': count},
      postId: postId,
    );
  }

  static Future<void> highlyRecommend({required int postId}) {
    return _postAction(
      'api/highlyRecommends',
      data: <String, Object?>{'post_id': postId},
      postId: postId,
    );
  }

  static Future<void> reward({required int postId, required int productId}) {
    return _postAction(
      'api/postContentTipCoins',
      data: <String, Object?>{'post_id': postId, 'goods_id': productId},
      postId: postId,
    );
  }

  static Future<void> sendFeedback({
    required int postId,
    required int reasonId,
    required String content,
  }) {
    return ApiClient().post<void>(
      'api/postContentFeedbacks',
      data: <String, Object?>{
        'question_id': reasonId,
        'other_question': content,
        'post_id': postId,
      },
      parser: (_) {},
      deduplicate: true,
    );
  }

  // 产品决定本期不开放帖子视频下载。旧接口契约暂时保留在注释中，
  // 避免业务层在本期误接入购买下载权限或下载地址请求。
  /*
  static Future<void> buyDownload({required int videoId}) {
    return ApiClient().post<void>(
      'api/buyDownloadVideos',
      data: <String, Object?>{'video_id': videoId},
      parser: (_) {},
      deduplicate: true,
    );
  }

  static Future<String> getDownloadUrl({required int videoId}) {
    return ApiClient().post<String>(
      'api/downloadVideos',
      data: <String, Object?>{'video_id': videoId},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid download data');
        return data['download']?.toString() ?? '';
      },
      deduplicate: true,
    );
  }
  */

  static Future<void> buy({required int postId}) {
    return _postAction(
      'api/postBuys',
      data: <String, Object?>{'post_id': postId},
      postId: postId,
    );
  }

  static Future<void> toggleFollow({
    required int postId,
    required int memberId,
  }) {
    return ApiClient().post<void>(
      'api/focusOns',
      data: <String, Object?>{'member_id': memberId},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{
        'post_detail_$postId',
        'search_users',
        'follow_users',
        'user_detail_$memberId',
      },
    );
  }

  static Future<void> _postAction(
    String path, {
    required Map<String, Object?> data,
    required int postId,
  }) {
    return ApiClient().post<void>(
      path,
      data: data,
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{
        'post_detail_$postId',
        'home_recommendations',
        'home_latest',
        'search_posts',
      },
    );
  }
}
