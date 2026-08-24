import 'package:b_flutter/models/app_version.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/home_content_section.dart';
import 'package:b_flutter/models/home_label.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class HomeApi {
  static Future<AppVersion?> getAppVersion() {
    return ApiClient().get<AppVersion?>(
      'api/versions',
      data: const <String, Object?>{'type': 0},
      parser: (data) {
        if (data is! Map) return null;
        return AppVersion.fromJson(Map<String, dynamic>.from(data));
      },
      showErrorToast: true,
    );
  }

  static Future<BannerItem?> getPopupAdvertisement() {
    return ApiClient().get<BannerItem?>(
      'api/popUpsBanners',
      data: const <String, Object?>{},
      parser: (data) {
        if (data is! Map) return null;
        return BannerItem.fromJson(Map<String, dynamic>.from(data));
      },
      showErrorToast: true,
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

  static Future<List<HomeCategory>> getNavigation({
    int type = 1,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<HomeCategory>>(
      'api/navigationTypes',
      data: <String, Object?>{'type': type},
      parser: (data) => _parseList(data, HomeCategory.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 10))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 10)),
      cacheTags: <String>{'home_navigation_$type'},
    );
  }

  static Future<List<BannerItem>> getContentBanners({
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<BannerItem>>(
      'api/contentListBanners',
      data: const <String, Object?>{},
      parser: (data) => _parseList(data, BannerItem.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 3))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 3)),
      cacheTags: const <String>{'home_banners'},
    );
  }

  static Future<List<BannerItem>> getTopBanners({bool forceRefresh = false}) {
    return ApiClient().get<List<BannerItem>>(
      'api/topBanners',
      data: const <String, Object?>{},
      parser: (data) => _parseList(data, BannerItem.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 3))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 3)),
      cacheTags: const <String>{'home_top_banners'},
    );
  }

  static Future<PagedResult<PostSummary>> getRecommendations({
    required int page,
    int sortType = 3,
    bool forceRefresh = false,
  }) {
    return _getPostPage(
      'api/homeRecommends',
      data: <String, Object?>{
        'page': page,
        'size': 16,
        'shcool': 0,
        'order_sort': 1,
        'order_sort_type': sortType,
      },
      forceRefresh: forceRefresh,
      cacheTag: 'home_recommendations',
    );
  }

  static Future<PagedResult<PostSummary>> getLatest({
    required int page,
    bool forceRefresh = false,
  }) {
    return _getPostPage(
      'api/hotRecommends',
      data: <String, Object?>{'topic_id': 0, 'page': page},
      forceRefresh: forceRefresh,
      cacheTag: 'home_latest',
    );
  }

  static Future<PagedResult<PostSummary>> getCategoryPosts({
    required int categoryId,
    required int childCategoryId,
    required int page,
    int sort = 1,
    bool forceRefresh = false,
    int size = 16,
    int labelId = 0,
  }) {
    return _getPostPage(
      'api/postContentLists',
      data: <String, Object?>{
        'page': page,
        'plate_one_id': categoryId,
        'plate_two_id': childCategoryId,
        'title': '',
        'label_id': labelId,
        'order_sort': sort,
        'size': size,
        'collection_id': '',
      },
      forceRefresh: forceRefresh,
      cacheTag: 'home_category_$categoryId',
    );
  }

  static Future<List<HomeLabel>> getCategoryLabels({required int categoryId}) {
    return ApiClient().get<List<HomeLabel>>(
      'api/classifyLabels',
      data: <String, Object?>{'id': categoryId},
      parser: (data) => _parseList(data, HomeLabel.fromJson),
      cachePolicy: const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
      cacheTags: <String>{'home_labels_$categoryId'},
    );
  }

  static Future<List<HomeContentSection>> getCategorySections({
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<HomeContentSection>>(
      'api/topPostContentLists',
      data: <String, Object?>{'plate_id': categoryId},
      parser: (data) => _parseList(data, HomeContentSection.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: <String>{'home_sections_$categoryId'},
    );
  }

  static Future<List<HomeCategory>> getMovieSections({
    required int categoryId,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<List<HomeCategory>>(
      'api/videoTypes',
      data: <String, Object?>{'plate_one_id': categoryId},
      parser: (data) => _parseList(data, HomeCategory.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 5))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 5)),
      cacheTags: <String>{'home_movie_sections_$categoryId'},
    );
  }

  static Future<List<TopicSummary>> getTopics({bool forceRefresh = false}) {
    return ApiClient().get<List<TopicSummary>>(
      'api/topics',
      data: const <String, Object?>{'keyword': ''},
      parser: (data) => _parseList(data, TopicSummary.fromJson),
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 2))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 2)),
      cacheTags: const <String>{'home_topics'},
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
        if (value is! Map) throw const FormatException('Invalid page data');
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(value),
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{cacheTag},
    );
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
