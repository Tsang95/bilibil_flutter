import 'package:b_flutter/models/advertising_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class AdvertisingApi {
  static Future<AdvertisingDashboard> getDashboard({
    required int page,
    bool forceRefresh = false,
  }) =>
      ApiClient().get<AdvertisingDashboard>(
        'api/memberAdvertiseLists',
        data: <String, Object?>{'page': page},
        parser: (data) {
          if (data is! Map) {
            throw const FormatException('Invalid advertising data');
          }
          return AdvertisingDashboard.fromJson(Map<String, dynamic>.from(data));
        },
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
            : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
        cacheTags: const <String>{'advertising_dashboard'},
      );

  static Future<PagedResult<AdvertisingRecord>> getMyAdvertisements({
    required int status,
    required int page,
    bool forceRefresh = false,
  }) =>
      ApiClient().get<PagedResult<AdvertisingRecord>>(
        'api/ownAdvertisingLists',
        data: <String, Object?>{'status': status, 'page': page},
        parser: (data) {
          if (data is! Map) {
            throw const FormatException('Invalid advertising page');
          }
          return PagedResult<AdvertisingRecord>.fromJson(
            Map<String, dynamic>.from(data),
            AdvertisingRecord.fromJson,
          );
        },
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(seconds: 30))
            : const CachePolicy.cacheFirst(ttl: Duration(seconds: 30)),
        cacheTags: const <String>{'advertising_records'},
      );

  static Future<List<AdvertisingPlacement>> getPlacements({
    bool forceRefresh = false,
  }) =>
      ApiClient().get<List<AdvertisingPlacement>>(
        'api/advertisingLocations',
        parser: _parsePlacements,
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
            : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
        cacheTags: const <String>{'advertising_placements'},
      );

  static Future<List<AdvertisingPrice>> getPrices({required int placementId}) =>
      ApiClient().get<List<AdvertisingPrice>>(
        'api/advertisingLocationPrices',
        data: <String, Object?>{'location_id': placementId},
        parser: (data) => data is List
            ? data
                .whereType<Map>()
                .map(
                  (item) => AdvertisingPrice.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
            : const <AdvertisingPrice>[],
      );

  static Future<void> submit({required Map<String, Object?> data}) =>
      ApiClient().post<void>(
        'api/advertisingDeliveries',
        data: data,
        parser: (_) {},
        deduplicate: true,
        invalidateCacheTags: const <String>{
          'advertising_dashboard',
          'advertising_records',
        },
      );

  static List<AdvertisingPlacement> _parsePlacements(Object? data) =>
      data is List
          ? data
              .whereType<Map>()
              .map(
                (item) => AdvertisingPlacement.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <AdvertisingPlacement>[];
}
