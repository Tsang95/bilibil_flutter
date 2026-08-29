import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/post_summary.dart';

final class HomeContentSection {
  const HomeContentSection({required this.category, required this.items});

  factory HomeContentSection.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['twoObj'];
    final rawItems = json['detailList'];
    return HomeContentSection(
      category: rawCategory is Map
          ? HomeCategory.fromJson(Map<String, dynamic>.from(rawCategory))
          : HomeCategory.fromJson(const <String, dynamic>{}),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => PostSummary.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const <PostSummary>[],
    );
  }

  final HomeCategory category;
  final List<PostSummary> items;
}
