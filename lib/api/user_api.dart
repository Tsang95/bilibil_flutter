import 'package:b_flutter/models/charge_member.dart';
import 'package:b_flutter/models/charge_subscription_product.dart';
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
}
