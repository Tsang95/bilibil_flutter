final class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.backgroundUrl,
    required this.itemCount,
    required this.styleType,
    required this.showModel,
    required this.children,
  });

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['son_type'];
    return HomeCategory(
      id: _integer(json['id']),
      parentId: _integer(json['pid']),
      name: _string(json['name']),
      backgroundUrl: _string(json['backgroup_picture']),
      itemCount: _integer(json['num']),
      styleType: _integer(json['style_type']),
      showModel: _integer(json['show_model']),
      children: rawChildren is List
          ? rawChildren
              .whereType<Map>()
              .map(
                (item) =>
                    HomeCategory.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const <HomeCategory>[],
    );
  }

  final int id;
  final int parentId;
  final String name;
  final String backgroundUrl;
  final int itemCount;
  final int styleType;
  final int showModel;
  final List<HomeCategory> children;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
