import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class GameApi {
  static Future<List<BannerItem>> getBanners({bool forceRefresh = false}) =>
      ApiClient().get<List<BannerItem>>(
        'api/gameTopBanners',
        data: const <String, Object?>{},
        parser: (data) => _list(data, BannerItem.fromJson),
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(minutes: 3))
            : const CachePolicy.cacheFirst(ttl: Duration(minutes: 3)),
        cacheTags: const <String>{'game_banners'},
      );

  static Future<List<GameCategory>> getCategories({
    bool forceRefresh = false,
  }) => ApiClient().post<List<GameCategory>>(
    'api/gamenew/gamelist',
    data: const <String, Object?>{},
    parser: (data) {
      final value = _nestedData(data);
      if (value is! Map) return const <GameCategory>[];
      return value.values
          .whereType<Map>()
          .map((item) => GameCategory.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
    cacheTags: const <String>{'game_categories'},
  );

  static Future<int> getBalance() => ApiClient().post<int>(
    'api/gamenew/gamebalance',
    data: const <String, Object?>{},
    parser: (data) {
      final value = _nestedData(data);
      if (value is! Map) return 0;
      return _integer(value['balance']);
    },
    cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'game_balance'},
  );

  static Future<List<GameActivity>> getActivities({
    bool forceRefresh = false,
  }) => ApiClient().post<List<GameActivity>>(
    'api/gamenew/activeList',
    data: const <String, Object?>{'category_id': 1},
    parser: (data) {
      final value = _nestedData(data);
      return _list(value, GameActivity.fromJson);
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
    cacheTags: const <String>{'game_activities'},
  );

  static Future<GameLaunch> enterGame({required int gameId}) =>
      ApiClient().post<GameLaunch>(
        'api/gamenew/gameurl',
        data: <String, Object?>{'game_id': gameId},
        parser: (data) {
          final value = _nestedData(data);
          if (value is! Map) throw const FormatException('Invalid game launch');
          final launch = GameLaunch.fromJson(Map<String, dynamic>.from(value));
          if (launch.url.trim().isEmpty) {
            throw const FormatException('Missing game launch URL');
          }
          return launch;
        },
        deduplicate: true,
        showErrorToast: true,
      );

  static Future<void> exitGame({required int platformId}) {
    if (platformId <= 0) return Future<void>.value();
    return ApiClient().post<void>(
      'api/gamenew/gameexit',
      data: <String, Object?>{'platform_id': platformId},
      parser: (_) {},
      deduplicate: true,
    );
  }

  static Future<List<GameRechargeRecord>> getRechargeRecords({
    required int lastId,
  }) => ApiClient().post<List<GameRechargeRecord>>(
    'api/gamenew/chargelist',
    data: <String, Object?>{'last_id': lastId, 'size': 20},
    parser: (data) {
      final value = _nestedData(data);
      return _list(
        value is Map ? value['list'] : value,
        GameRechargeRecord.fromJson,
      );
    },
    cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'game_recharge_records'},
  );

  static Future<GameWithdrawNeed> getWithdrawNeed() =>
      ApiClient().post<GameWithdrawNeed>(
        'api/gamenew/paymentDrawNeed',
        data: const <String, Object?>{},
        parser: (data) {
          final value = _nestedData(data);
          if (value is! Map) {
            throw const FormatException('Invalid withdrawal prerequisites');
          }
          return GameWithdrawNeed.fromJson(Map<String, dynamic>.from(value));
        },
        deduplicate: true,
        showErrorToast: true,
      );

  static Future<List<GameBank>> getBanks() => ApiClient().post<List<GameBank>>(
    'api/gamenew/banklist',
    data: const <String, Object?>{},
    parser: (data) => _list(_nestedData(data), GameBank.fromJson),
    cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
    cacheTags: const <String>{'game_banks'},
  );

  static Future<GameBankBinding> bindBank({
    required String accountName,
    required String cardNumber,
    required GameBank bank,
  }) => ApiClient().post<GameBankBinding>(
    'api/gamenew/bankbind',
    data: <String, Object?>{
      'bank_name': bank.name,
      'card_num': cardNumber,
      'account_name': accountName,
      'bank_id': bank.id,
    },
    parser: (data) {
      final value = _nestedData(data);
      if (value is! Map) throw const FormatException('Invalid bank binding');
      return GameBankBinding.fromJson(Map<String, dynamic>.from(value));
    },
    lock: true,
    deduplicate: true,
    showErrorToast: true,
    invalidateCacheTags: const <String>{'game_withdraw_need'},
  );

  static Future<void> withdraw({required double amount}) =>
      ApiClient().post<void>(
        'api/gamenew/paymentWithdraw',
        data: <String, Object?>{'amount': amount, 'type': '0'},
        parser: (_) {},
        lock: true,
        deduplicate: true,
        showErrorToast: true,
        invalidateCacheTags: const <String>{
          'game_balance',
          'game_withdraw_records',
        },
      );

  static Future<List<GameRechargeRecord>> getWithdrawRecords({
    required int lastId,
  }) => ApiClient().post<List<GameRechargeRecord>>(
    'api/gamenew/withdrawlist',
    data: <String, Object?>{'last_id': lastId, 'size': 20},
    parser: (data) {
      final value = _nestedData(data);
      return _list(
        value is Map ? value['list'] : value,
        GameRechargeRecord.fromJson,
      );
    },
    cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
    cacheTags: const <String>{'game_withdraw_records'},
  );

  static Future<List<GameRechargeCategory>> getRechargeCategories() =>
      ApiClient().post<List<GameRechargeCategory>>(
        'api/gamenew/paymentcat',
        data: const <String, Object?>{},
        parser: (data) =>
            _list(_nestedData(data), GameRechargeCategory.fromJson),
        cachePolicy: const CachePolicy.networkFirst(ttl: Duration(minutes: 2)),
        cacheTags: const <String>{'game_recharge_categories'},
      );

  static Future<List<GamePaymentChannel>> getPaymentChannels({
    required int categoryId,
  }) => ApiClient().post<List<GamePaymentChannel>>(
    'api/gamenew/paymentlist',
    data: <String, Object?>{'id': categoryId},
    parser: (data) {
      final value = _nestedData(data);
      return _list(
        value is Map ? value['paymentListColumn'] : value,
        GamePaymentChannel.fromJson,
      );
    },
    cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
    cacheTags: const <String>{'game_payment_channels'},
  );

  static Future<GameLaunch> createRecharge({
    required int channelId,
    required String amount,
  }) => ApiClient().post<GameLaunch>(
    'api/gamenew/paymentInline',
    data: <String, Object?>{
      'amount': amount,
      'pid': channelId,
      'device_type': 2,
    },
    parser: (data) {
      final value = _nestedData(data);
      if (value is! Map) throw const FormatException('Invalid recharge URL');
      final launch = GameLaunch.fromJson(Map<String, dynamic>.from(value));
      if (launch.url.trim().isEmpty) {
        throw const FormatException('Missing recharge URL');
      }
      return launch;
    },
    deduplicate: true,
    showErrorToast: true,
    invalidateCacheTags: const <String>{'game_recharge_records'},
  );

  static List<T> _list<T>(
    Object? data,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (data is! List) return <T>[];
    return data
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static Object? _nestedData(Object? value) {
    var current = value;
    while (current is Map && current.containsKey('data')) {
      current = current['data'];
    }
    return current;
  }

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
