class UserChargePrice {
  const UserChargePrice({
    required this.month,
    required this.quarter,
    required this.year,
  });

  final int month;
  final int quarter;
  final int year;

  factory UserChargePrice.fromJson(Map<String, dynamic> json) =>
      UserChargePrice(
        month: _asInt(json['month']),
        quarter: _asInt(json['quarter']),
        year: _asInt(json['year']),
      );
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
