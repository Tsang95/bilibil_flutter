import 'package:dio/dio.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/charge_member.dart';
import 'package:b_flutter/models/charge_subscription_product.dart';
import 'package:b_flutter/models/follow_user.dart';
import 'package:b_flutter/models/fan_user.dart';
import 'package:b_flutter/models/google_verify_data.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/suggestion_reason.dart';
import 'package:b_flutter/models/task_models.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/models/user_charge_price.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class UserApi {
  static Future<List<VipProduct>> getMovieVipProducts({
    bool forceRefresh = false,
  }) => _getVipProducts(
    'api/moviesGoodsLists',
    cacheTag: 'movie_vip_products',
    forceRefresh: forceRefresh,
  );

  static Future<List<VipProduct>> getCreatorVipProducts({
    bool forceRefresh = false,
  }) => _getVipProducts(
    'api/mediaGoodsLists',
    cacheTag: 'creator_vip_products',
    forceRefresh: forceRefresh,
  );

  static Future<List<VipProduct>> _getVipProducts(
    String path, {
    required String cacheTag,
    required bool forceRefresh,
  }) {
    return ApiClient().get<List<VipProduct>>(
      path,
      parser: (data) => data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) =>
                      VipProduct.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.id > 0)
                .toList(growable: false)
          : const <VipProduct>[],
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(hours: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(hours: 1)),
      cacheTags: <String>{cacheTag},
    );
  }

  static Future<void> buyMovieVip({required int productId}) =>
      _buyVip('api/buyMoviesVips', productId: productId);

  static Future<void> buyCreatorVip({required int productId}) =>
      _buyVip('api/buyMediaVips', productId: productId);

  static Future<void> _buyVip(String path, {required int productId}) {
    return ApiClient().post<void>(
      path,
      data: <String, Object?>{'goods_id': productId},
      parser: (_) {},
      lock: true,
      lockText: '购买中...',
      showErrorToast: true,
      deduplicate: true,
      invalidateCacheTags: const <String>{'current_user'},
    );
  }

  static Future<PagedResult<WalletChangeRecord>> getWalletChanges({
    required int page,
    bool forceRefresh = false,
  }) => ApiClient().get<PagedResult<WalletChangeRecord>>(
    'api/moneyChanges',
    data: <String, Object?>{'page': page},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid wallet records');
      return PagedResult<WalletChangeRecord>.fromJson(
        Map<String, dynamic>.from(data),
        WalletChangeRecord.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'wallet_changes'},
  );

  static Future<List<RechargeProduct>> getRechargeProducts() =>
      ApiClient().get<List<RechargeProduct>>(
        'api/walletGoodsLists',
        parser: (data) => data is List
            ? data
                  .whereType<Map>()
                  .map(
                    (item) => RechargeProduct.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList(growable: false)
            : const <RechargeProduct>[],
        cachePolicy: const CachePolicy.networkFirst(ttl: Duration(minutes: 1)),
        cacheTags: const <String>{'recharge_products'},
      );

  static Future<List<RechargeChannel>> getRechargeChannels({
    required double amount,
  }) => ApiClient().get<List<RechargeChannel>>(
    'api/channelLists',
    data: <String, Object?>{'amount': amount},
    parser: (data) => data is List
        ? data
              .whereType<Map>()
              .map(
                (item) =>
                    RechargeChannel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <RechargeChannel>[],
    cachePolicy: const CachePolicy.disabled(),
  );

  static Future<RechargeOrder> createRechargeOrder({
    required int productId,
    required int channelId,
  }) => ApiClient().post<RechargeOrder>(
    'api/payOrders',
    data: <String, Object?>{
      'goods_id': productId,
      'channel_id': channelId,
      'channel': AppEnvironment.channel,
      'equipment': 'android',
    },
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid recharge order');
      return RechargeOrder.fromJson(Map<String, dynamic>.from(data));
    },
    lock: true,
    lockText: '创建订单中...',
    showErrorToast: true,
    deduplicate: true,
    invalidateCacheTags: const <String>{'recharge_history'},
  );

  static Future<PagedResult<RechargeHistoryRecord>> getRechargeHistory({
    required int page,
    bool forceRefresh = false,
  }) => ApiClient().get<PagedResult<RechargeHistoryRecord>>(
    'api/orderLists',
    data: <String, Object?>{'page': page},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid recharge history');
      return PagedResult<RechargeHistoryRecord>.fromJson(
        Map<String, dynamic>.from(data),
        RechargeHistoryRecord.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'recharge_history'},
  );

  static Future<void> withdrawGold({
    required WithdrawLinkType linkType,
    required String coinAddress,
    required String qrCodeUrl,
    required int goldAmount,
    required String payPassword,
  }) => ApiClient().post<void>(
    'api/withdrawMoneys',
    data: <String, Object?>{
      'link_type': linkType.value,
      'coin_address': coinAddress,
      'address_qr_code': qrCodeUrl,
      'gold_num': goldAmount,
      'pay_pwd': payPassword,
    },
    parser: (_) {},
    lock: true,
    lockText: '提现中...',
    showErrorToast: true,
    deduplicate: true,
    invalidateCacheTags: const <String>{
      'current_user',
      'wallet_changes',
      'withdraw_history',
    },
  );

  static Future<PagedResult<WithdrawRecord>> getWithdrawHistory({
    required int page,
    bool forceRefresh = false,
  }) => ApiClient().get<PagedResult<WithdrawRecord>>(
    'api/withdrawLogs',
    data: <String, Object?>{'page': page},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid withdraw history');
      return PagedResult<WithdrawRecord>.fromJson(
        Map<String, dynamic>.from(data),
        WithdrawRecord.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
        : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'withdraw_history'},
  );

  static Future<DailyTaskSummary> getDailyTaskSummary() {
    return ApiClient().get<DailyTaskSummary>(
      'api/signGoodsLists',
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid sign task');
        return DailyTaskSummary.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'daily_tasks'},
    );
  }

  static Future<List<TaskItem>> getTasks({required int type}) {
    return ApiClient().get<List<TaskItem>>(
      'api/taskLists',
      data: <String, Object?>{'type': type},
      parser: (data) => data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) => TaskItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <TaskItem>[],
      cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
      cacheTags: <String>{'tasks_$type'},
    );
  }

  static Future<void> signDailyTask({required int rewardId}) {
    return ApiClient().post<void>(
      'api/memberSigns',
      data: <String, Object?>{'sign_goods_id': rewardId},
      parser: (_) {},
      lock: true,
      lockText: '签到中...',
      showErrorToast: true,
      deduplicate: true,
      invalidateCacheTags: const <String>{'daily_tasks', 'current_user'},
    );
  }

  static Future<void> updateProfile({
    required String nickname,
    required String avatarUrl,
    required int gender,
    required String signature,
    required String backgroundUrl,
  }) {
    return ApiClient().post<void>(
      'api/updateUsers',
      data: <String, Object?>{
        'nickname': nickname,
        'head_sculpture': avatarUrl,
        'gender': gender,
        'sign': signature,
        'background': backgroundUrl,
      },
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: const <String>{'current_user'},
    );
  }

  static Future<String> uploadProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return ApiClient().post<String>(
      'api/uploads',
      data: form,
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid upload result');
        final url = data['url']?.toString() ?? '';
        if (url.isEmpty) throw const FormatException('Empty upload url');
        return url;
      },
      deduplicate: false,
    );
  }

  static Future<UserChargePrice> getChargePrice() {
    return ApiClient().get<UserChargePrice>(
      'api/subGoodsDetails',
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid charge price');
        return UserChargePrice.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'charge_price'},
    );
  }

  static Future<void> updateChargePrice({
    required int month,
    required int quarter,
    required int year,
  }) {
    return ApiClient().post<void>(
      'api/subGoodsUpdates',
      data: <String, Object?>{'month': month, 'quarter': quarter, 'year': year},
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: const <String>{'charge_price'},
    );
  }

  static Future<void> submitUserFeedback({required String content}) {
    return ApiClient().post<void>(
      'api/feedbacks',
      data: <String, Object?>{'content': content},
      parser: (_) {},
      deduplicate: true,
    );
  }

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

  static Future<PagedResult<FanUser>> getFollowingUsers({
    required int page,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<FanUser>>(
      'api/focusOnLists',
      data: <String, Object?>{'page': page, 'size': 10},
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid following list');
        return PagedResult<FanUser>.fromJson(
          Map<String, dynamic>.from(data),
          FanUser.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
          : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
      cacheTags: const <String>{'following_users'},
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
        'following_users',
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
