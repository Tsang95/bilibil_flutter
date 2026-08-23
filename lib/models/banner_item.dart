final class BannerItem {
  const BannerItem({
    required this.id,
    required this.name,
    required this.pictureUrl,
    required this.type,
    required this.outsideUrl,
    required this.insideUrl,
    required this.category,
    required this.html,
    required this.advertiseOrderId,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: _integer(json['id']),
      name: _string(json['name']),
      pictureUrl: _string(json['picture_url']),
      type: _integer(json['type']),
      outsideUrl: _string(json['out_jump_url']),
      insideUrl: _string(json['inside_jump_url']),
      category: _integer(json['cate']),
      html: _string(json['html']),
      advertiseOrderId: _integer(
        json['advertise_order_id'] ?? json['advertise_order_id '],
      ),
    );
  }

  final int id;
  final String name;
  final String pictureUrl;
  final int type;
  final String outsideUrl;
  final String insideUrl;
  final int category;
  final String html;
  final int advertiseOrderId;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
