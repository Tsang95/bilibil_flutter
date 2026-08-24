import 'package:b_flutter/models/help_item.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class HelpApi {
  static Future<List<HelpItem>> getItems({bool forceRefresh = false}) =>
      ApiClient().get<List<HelpItem>>(
        'api/helpLists',
        data: const <String, Object?>{},
        parser: (data) {
          if (data is! List) return const <HelpItem>[];
          return data
              .whereType<Map>()
              .map((item) => HelpItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false);
        },
        cachePolicy: forceRefresh
            ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
            : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
        cacheTags: const <String>{'help_items'},
      );
}
