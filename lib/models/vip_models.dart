final class VipProduct {
  const VipProduct({
    required this.id,
    required this.name,
    required this.days,
    required this.price,
    required this.oldPrice,
    required this.commentLimit,
    required this.privateMessageLimit,
    required this.postLimit,
    required this.categoryNames,
  });

  factory VipProduct.fromJson(Map<String, dynamic> json) => VipProduct(
    id: _integer(json['id']),
    name: json['name']?.toString() ?? '',
    days: _integer(json['real_day']),
    price: _number(json['price']),
    oldPrice: _number(json['old_price']),
    commentLimit: _integer(json['comment_num']),
    privateMessageLimit: _integer(json['private_letter_num']),
    postLimit: _integer(json['post_num']),
    categoryNames: (json['circleObj'] ?? json['circle_obj']) is List
        ? ((json['circleObj'] ?? json['circle_obj']) as List)
              .whereType<Map>()
              .map((item) => item['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[],
  );

  final int id;
  final String name;
  final int days;
  final double price;
  final double oldPrice;
  final int commentLimit;
  final int privateMessageLimit;
  final int postLimit;
  final List<String> categoryNames;

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

final class WalletChangeRecord {
  const WalletChangeRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.amount,
    required this.createdAt,
  });

  factory WalletChangeRecord.fromJson(Map<String, dynamic> json) =>
      WalletChangeRecord(
        id: VipProduct._integer(json['id']),
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        amount: VipProduct._number(json['gold_num']),
        createdAt: json['created_at']?.toString() ?? '',
      );

  final int id;
  final String title;
  final String content;
  final double amount;
  final String createdAt;
}

final class RechargeProduct {
  const RechargeProduct({
    required this.id,
    required this.goldCoin,
    required this.price,
    required this.oldPrice,
    required this.isSelected,
    required this.additional,
  });

  factory RechargeProduct.fromJson(Map<String, dynamic> json) =>
      RechargeProduct(
        id: VipProduct._integer(json['id']),
        goldCoin: VipProduct._integer(json['gold_coin']),
        price: VipProduct._number(json['price']),
        oldPrice: VipProduct._number(json['old_price']),
        isSelected: VipProduct._integer(json['is_selected']) == 1,
        additional: json['additional']?.toString() ?? '',
      );

  final int id;
  final int goldCoin;
  final double price;
  final double oldPrice;
  final bool isSelected;
  final String additional;
}

final class RechargeChannel {
  const RechargeChannel({
    required this.id,
    required this.type,
    required this.name,
  });

  factory RechargeChannel.fromJson(Map<String, dynamic> json) =>
      RechargeChannel(
        id: VipProduct._integer(json['id']),
        type: VipProduct._integer(json['type']),
        name: json['desc']?.toString() ?? '',
      );

  final int id;
  final int type;
  final String name;
}

final class RechargeOrder {
  const RechargeOrder({required this.url});

  factory RechargeOrder.fromJson(Map<String, dynamic> json) =>
      RechargeOrder(url: json['pay_url']?.toString() ?? '');

  final String url;
}

final class RechargeHistoryRecord {
  const RechargeHistoryRecord({
    required this.id,
    required this.amount,
    required this.createdAt,
    required this.isPaid,
  });

  factory RechargeHistoryRecord.fromJson(Map<String, dynamic> json) =>
      RechargeHistoryRecord(
        id: VipProduct._integer(json['id']),
        amount: VipProduct._number(json['money']),
        createdAt: json['created_at']?.toString() ?? '',
        isPaid: VipProduct._integer(json['pay_status']) == 1,
      );

  final int id;
  final double amount;
  final String createdAt;
  final bool isPaid;
}
