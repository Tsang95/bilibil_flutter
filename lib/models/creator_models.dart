final class CreatorDashboard {
  const CreatorDashboard({
    required this.allCount,
    required this.reviewingCount,
    required this.collectionCount,
    required this.incomes,
  });

  factory CreatorDashboard.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    final count = rawCount is Map
        ? Map<String, dynamic>.from(rawCount)
        : const <String, dynamic>{};
    final rawIncome = json['income'];
    final income = rawIncome is Map
        ? Map<String, dynamic>.from(rawIncome)
        : const <String, dynamic>{};
    final rawList = income['list'];
    return CreatorDashboard(
      allCount: _integer(count['sun_count']),
      reviewingCount: _integer(count['ing_count']),
      collectionCount: _integer(count['collection_count']),
      incomes: rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) =>
                      CreatorIncome.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <CreatorIncome>[],
    );
  }

  final int allCount;
  final int reviewingCount;
  final int collectionCount;
  final List<CreatorIncome> incomes;
}

final class CreatorIncome {
  const CreatorIncome({
    required this.id,
    required this.goldAmount,
    required this.postTitle,
    required this.createdAt,
  });

  factory CreatorIncome.fromJson(Map<String, dynamic> json) => CreatorIncome(
    id: _integer(json['id']),
    goldAmount: _number(json['gold_num']),
    postTitle: _string(json['post_title']),
    createdAt: _string(json['created_at']),
  );

  final int id;
  final double goldAmount;
  final String postTitle;
  final String createdAt;

  String get formattedGold => goldAmount == goldAmount.truncateToDouble()
      ? goldAmount.toInt().toString()
      : goldAmount.toString();
}

enum CreatorWorkStatus {
  published(1, '发布成功'),
  reviewing(0, '审核中'),
  rejected(-1, '审核失败');

  const CreatorWorkStatus(this.value, this.label);

  final int value;
  final String label;
}

final class CreatorWork {
  const CreatorWork({
    required this.id,
    required this.title,
    required this.coverUrls,
    required this.vipOnly,
    required this.salesCount,
    required this.viewsCount,
    required this.collectCount,
    required this.categoryName,
    required this.reason,
  });

  factory CreatorWork.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['plate_two_obj'];
    final category = rawCategory is Map
        ? Map<String, dynamic>.from(rawCategory)
        : const <String, dynamic>{};
    final rawCovers = json['cover_images'];
    return CreatorWork(
      id: _integer(json['id']),
      title: _string(json['title']),
      coverUrls: rawCovers is List
          ? rawCovers
                .map(_string)
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      vipOnly: _integer(json['is_vip_watch']) == 1,
      salesCount: _integer(json['sales_num']),
      viewsCount: _integer(json['views_num']),
      collectCount: _integer(json['collect_num']),
      categoryName: _string(category['name']),
      reason: _string(json['reason']),
    );
  }

  final int id;
  final String title;
  final List<String> coverUrls;
  final bool vipOnly;
  final int salesCount;
  final int viewsCount;
  final int collectCount;
  final String categoryName;
  final String reason;

  String get preferredCoverUrl => coverUrls.isEmpty ? '' : coverUrls.first;
}

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
