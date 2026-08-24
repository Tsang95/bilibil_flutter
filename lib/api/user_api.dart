import 'package:b_flutter/models/charge_member.dart';
import 'package:b_flutter/models/charge_subscription_product.dart';
import 'package:b_flutter/models/follow_user.dart';
import 'package:b_flutter/models/fan_user.dart';
import 'package:b_flutter/models/google_verify_data.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/suggestion_reason.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class UserApi {
  static Future<List<SuggestionReason>> getSuggestionReasons() {
    return ApiClient().get<List<SuggestionReason>>(
      'api/suggestionTypes',
      data: const <String, Object?>{},
      parser: (data) {
        if (data is! List) return const <SuggestionReason>[];
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  SuggestionReason.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
      lock: true,
      showErrorToast: true,
    );
  }

  static Future<void> submitSuggestion({
    required int type,
    required String content,
    required int score,
  }) {
    return ApiClient().post<void>(
      'api/newSuggestions',
      data: <String, Object?>{'type': type, 'content': content, 'score': score},
      parser: (_) {},
      lock: true,
      lockText: '加载中...',
      showErrorToast: true,
      deduplicate: true,
    );
  }

  static Future<ChargeMember> getChargeMember({required int userId}) {
    return ApiClient().get<ChargeMember>(
      'api/ownContentMemberDetails',
      data: <String, Object?>{'member_id': userId},
      parser: (data) {
        if (data is! Map) {
          throw const FormatException('Invalid charge member');
        }
        return ChargeMember.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'charge_member_$userId'},
    );
  }

  static Future<List<ChargeSubscriptionProduct>> getChargeProducts({
    required int userId,
  }) {
    return ApiClient().get<List<ChargeSubscriptionProduct>>(
      'api/subGoodsLists',
      data: <String, Object?>{'member_id': userId},
      parser: (data) {
        if (data is! List) {
          throw const FormatException('Invalid charge product list');
        }
        return data
            .whereType<Map>()
            .map(
              (item) => ChargeSubscriptionProduct.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.id > 0)
            .toList(growable: false);
      },
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'charge_products_$userId'},
    );
  }

  static Future<void> buySubscription({
    required int userId,
    required int productId,
  }) {
    return ApiClient().post<void>(
      'api/buySubscriptions',
      data: <String, Object?>{
        'subscription_member_id': userId,
        'goods_id': productId,
      },
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: <String>{
        'charge_products_$userId',
        'charge_member_$userId',
        'current_user',
      },
    );
  }

  static Future<UserInfo> getCurrentUser({bool cache = false}) {
    return ApiClient().get<UserInfo>(
      'api/memberDetails',
      parser: (data) {
        if (data is! Map) {
          throw const FormatException('Invalid user profile');
        }
        return UserInfo.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: cache
          ? const CachePolicy.cacheFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.disabled(),
      cacheTags: const <String>{'current_user'},
    );
  }

  static Future<PagedResult<FollowUser>> getFollowedUsers({
    required String keyword,
    required int sort,
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<FollowUser>>(
      'api/accessLogs',
      data: <String, Object?>{'keyword': keyword, 'sort': sort, 'page': page},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid follow list');
        return PagedResult<FollowUser>.fromJson(
          Map<String, dynamic>.from(data),
          FollowUser.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'follow_users'},
    );
  }

  static Future<PagedResult<FanUser>> getFans({
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<FanUser>>(
      'api/memberFanLists',
      data: <String, Object?>{'page': page, 'size': 10},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid fans list');
        return PagedResult<FanUser>.fromJson(
          Map<String, dynamic>.from(data),
          FanUser.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'fan_users'},
    );
  }

  static Future<void> toggleFollow({required int userId}) {
    return ApiClient().post<void>(
      'api/focusOns',
      data: <String, Object?>{'member_id': userId},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: const <String>{
        'fan_users',
        'follow_users',
        'search_users',
        'current_user',
      },
    );
  }

  static Future<GoogleVerifyData> createGoogleSecret() {
    return ApiClient().post<GoogleVerifyData>(
      'api/creatGoogleSecrets',
      parser: (data) {
        if (data is! Map) {
          throw const FormatException('Invalid Google verification data');
        }
        return GoogleVerifyData.fromJson(Map<String, dynamic>.from(data));
      },
      showErrorToast: true,
      deduplicate: false,
    );
  }

  static Future<void> bindGoogleSecret({
    required String key,
    required String code,
  }) {
    return ApiClient().post<void>(
      'api/bindGoogleSecrets',
      data: <String, Object?>{'google_key': key, 'code': code},
      parser: (_) {},
      lock: true,
      lockText: '绑定中...',
      showErrorToast: true,
      deduplicate: true,
      invalidateCacheTags: const <String>{'current_user'},
    );
  }

  static Future<void> setPayPassword({
    required String password,
    required String confirmPassword,
  }) {
    return ApiClient().post<void>(
      'api/setPayPasswords',
      data: <String, Object?>{
        'pay_pwd': password,
        're_pay_pwd': confirmPassword,
      },
      parser: (_) {},
      lock: true,
      lockText: '提交中...',
      showErrorToast: true,
      deduplicate: true,
      invalidateCacheTags: const <String>{'current_user'},
    );
  }

  static Future<PagedResult<PostSummary>> getViewHistory({
    required int page,
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return _getActionPostPage(
      'api/postHistories',
      page: page,
      categoryId: categoryId,
      forceRefresh: forceRefresh,
      cacheTag: 'view_history_$categoryId',
    );
  }

  static Future<PagedResult<PostSummary>> getOwnCollections({
    required int page,
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return _getActionPostPage(
      'api/ownCollects',
      page: page,
      categoryId: categoryId,
      forceRefresh: forceRefresh,
      cacheTag: 'own_collections_$categoryId',
    );
  }

  static Future<PagedResult<PostSummary>> getOwnBuys({
    required int page,
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return _getActionPostPage(
      'api/ownBuys',
      page: page,
      categoryId: categoryId,
      forceRefresh: forceRefresh,
      cacheTag: 'own_buys_$categoryId',
    );
  }

  static Future<PagedResult<PostSummary>> _getActionPostPage(
    String path, {
    required int page,
    required int categoryId,
    required bool forceRefresh,
    required String cacheTag,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      path,
      data: <String, Object?>{'page': page, 'plate_one_id': categoryId},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid history page');
        final pageData = Map<String, dynamic>.from(data);
        final rawItems = pageData['list'];
        if (rawItems is List) {
          pageData['list'] = rawItems
              .whereType<Map>()
              .map((item) {
                final record = Map<String, dynamic>.from(item);
                final post = record['post_obj'];
                return post is Map ? Map<String, dynamic>.from(post) : record;
              })
              .toList(growable: false);
        }
        return PagedResult<PostSummary>.fromJson(
          pageData,
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: <String>{cacheTag},
    );
  }
}
