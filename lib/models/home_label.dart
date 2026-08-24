final class HomeLabel {
  const HomeLabel({required this.id, required this.name});

  factory HomeLabel.fromJson(Map<String, dynamic> json) {
    return HomeLabel(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  final int id;
  final String name;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
