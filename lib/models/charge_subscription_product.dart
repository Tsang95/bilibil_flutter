final class ChargeSubscriptionProduct {
  const ChargeSubscriptionProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
  });

  factory ChargeSubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return ChargeSubscriptionProduct(
      id: _integer(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      price: _number(json['coin']),
      originalPrice: _number(json['old_coin']),
    );
  }

  final int id;
  final String name;
  final double price;
  final double originalPrice;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
