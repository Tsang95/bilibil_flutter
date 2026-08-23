final class SuggestionReason {
  const SuggestionReason({required this.id, required this.name});

  factory SuggestionReason.fromJson(Map<String, dynamic> json) {
    return SuggestionReason(
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
