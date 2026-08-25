import 'paged_result.dart';

final class AdvertisingPlacement {
  const AdvertisingPlacement({
    required this.id,
    required this.name,
    required this.coverImageTips,
    required this.previewImage,
    required this.width,
    required this.height,
  });

  factory AdvertisingPlacement.fromJson(Map<String, dynamic> json) =>
      AdvertisingPlacement(
        id: _integer(json['id']),
        name: _string(json['name']),
        coverImageTips: _string(json['cover_image_tips']),
        previewImage: _string(json['preview_image']),
        width: _integer(json['width']),
        height: _integer(json['height']),
      );

  final int id;
  final String name;
  final String coverImageTips;
  final String previewImage;
  final int width;
  final int height;
}

final class AdvertisingPrice {
  const AdvertisingPrice({
    required this.id,
    required this.months,
    required this.amount,
  });

  factory AdvertisingPrice.fromJson(Map<String, dynamic> json) =>
      AdvertisingPrice(
        id: _integer(json['id']),
        months: _integer(json['month_num']),
        amount: _integer(json['money']),
      );

  final int id;
  final int months;
  final int amount;
}

final class AdvertisingLocation {
  const AdvertisingLocation({
    required this.id,
    required this.name,
    required this.nickname,
    required this.avatarUrl,
  });

  factory AdvertisingLocation.fromJson(Map<String, dynamic> json) =>
      AdvertisingLocation(
        id: _integer(json['id']),
        name: _string(json['name']),
        nickname: _string(json['nickname']),
        avatarUrl: _string(json['head_sculpture']),
      );

  final int id;
  final String name;
  final String nickname;
  final String avatarUrl;
}

final class AdvertisingRecord {
  const AdvertisingRecord({
    required this.id,
    required this.location,
    required this.durationMonths,
    required this.type,
    required this.price,
    required this.targetUrl,
    required this.imageUrl,
    required this.clickCount,
    required this.status,
    required this.createdAt,
    required this.deadlineAt,
  });

  factory AdvertisingRecord.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['plate_obj'];
    return AdvertisingRecord(
      id: _integer(json['id']),
      location: rawLocation is Map
          ? AdvertisingLocation.fromJson(Map<String, dynamic>.from(rawLocation))
          : AdvertisingLocation.fromJson(const <String, dynamic>{}),
      durationMonths: _integer(json['duration']),
      type: _integer(json['type']),
      price: _integer(json['price']),
      targetUrl: _string(json['jump_url']),
      imageUrl: _string(json['advertise_image']),
      clickCount: _integer(json['click_num']),
      status: _integer(json['status']),
      createdAt: _string(json['created_at']),
      deadlineAt: _string(json['deadline_time']),
    );
  }

  final int id;
  final AdvertisingLocation location;
  final int durationMonths;
  final int type;
  final int price;
  final String targetUrl;
  final String imageUrl;
  final int clickCount;
  final int status;
  final String createdAt;
  final String deadlineAt;
}

final class AdvertisingSummary {
  const AdvertisingSummary({
    required this.successCount,
    required this.pendingCount,
    required this.failedCount,
    required this.expiredCount,
  });

  factory AdvertisingSummary.fromJson(Map<String, dynamic> json) =>
      AdvertisingSummary(
        successCount: _integer(json['success_num']),
        pendingCount: _integer(json['ing_num']),
        failedCount: _integer(json['fail_num']),
        expiredCount: _integer(json['invalidation_num']),
      );

  final int successCount;
  final int pendingCount;
  final int failedCount;
  final int expiredCount;
}

final class AdvertisingDashboard {
  const AdvertisingDashboard({required this.summary, required this.records});

  factory AdvertisingDashboard.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['total'];
    final rawRecords = json['advertiseObj'];
    return AdvertisingDashboard(
      summary: rawSummary is Map
          ? AdvertisingSummary.fromJson(Map<String, dynamic>.from(rawSummary))
          : AdvertisingSummary.fromJson(const <String, dynamic>{}),
      records: rawRecords is Map
          ? PagedResult<AdvertisingRecord>.fromJson(
              Map<String, dynamic>.from(rawRecords),
              AdvertisingRecord.fromJson,
            )
          : const PagedResult<AdvertisingRecord>(
              page: 1,
              totalPages: 0,
              totalItems: 0,
              isLastPage: true,
              items: <AdvertisingRecord>[],
            ),
    );
  }

  final AdvertisingSummary summary;
  final PagedResult<AdvertisingRecord> records;
}

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
