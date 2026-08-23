final class PostSummary {
  const PostSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.coverUrls,
    required this.horizontalCoverUrls,
    required this.durationSeconds,
    required this.viewCount,
    required this.collectCount,
    required this.likeCount,
    required this.salesCount,
    required this.isVipOnly,
    required this.isPurchased,
    required this.unlockType,
    required this.isOriginal,
    required this.label,
    required this.authorNickname,
    required this.categoryName,
    required this.createdAt,
    required this.primaryCategoryId,
  });

  factory PostSummary.fromJson(Map<String, dynamic> json) {
    final member = json['member_obj'];
    final category = json['plate_two_obj'];
    final price = _number(json['price']);
    final isVipOnly = _integer(json['is_vip_watch']) == 1;
    final unlockType = json.containsKey('is_buy')
        ? _integer(json['is_buy'])
        : isVipOnly
        ? 2
        : price > 0
        ? 1
        : 0;
    return PostSummary(
      id: _integer(json['id']),
      title: _string(json['title']),
      description: _string(json['describe']),
      type: _integer(json['type']),
      price: price,
      coverUrls: _stringList(json['cover_images']),
      horizontalCoverUrls: _stringList(json['horizontal_images']),
      durationSeconds: _integer(json['duration']),
      viewCount: _integer(json['views_num']),
      collectCount: _integer(json['collect_num']),
      likeCount: _integer(json['like_num']),
      salesCount: _integer(json['sales_num']),
      isVipOnly: isVipOnly,
      isPurchased: unlockType == 0 && price > 0,
      unlockType: unlockType,
      isOriginal: _integer(json['is_original']) == 1,
      label: _string(json['label']),
      authorNickname: member is Map ? _string(member['nickname']) : '',
      categoryName: category is Map ? _string(category['name']) : '',
      createdAt: DateTime.tryParse(_string(json['created_at'])),
      primaryCategoryId: _integer(json['plate_one_id']),
    );
  }

  final int id;
  final String title;
  final String description;
  final int type;
  final double price;
  final List<String> coverUrls;
  final List<String> horizontalCoverUrls;
  final int durationSeconds;
  final int viewCount;
  final int collectCount;
  final int likeCount;
  final int salesCount;
  final bool isVipOnly;
  final bool isPurchased;
  final int unlockType;
  final bool isOriginal;
  final String label;
  final String authorNickname;
  final String categoryName;
  final DateTime? createdAt;
  final int primaryCategoryId;

  String get preferredCoverUrl {
    if (primaryCategoryId == 6 && horizontalCoverUrls.isNotEmpty) {
      return horizontalCoverUrls.first;
    }
    return coverUrls.isEmpty ? '' : coverUrls.first;
  }

  String get accessBadgeText {
    if (unlockType == 1) return '${_formatPrice(price)}金币';
    if (unlockType == 2 || isVipOnly) return 'VIP';
    return '';
  }

  static String _formatPrice(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map(_string)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
