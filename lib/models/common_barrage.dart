final class CommonBarrage {
  const CommonBarrage({required this.id, required this.content});

  factory CommonBarrage.fromJson(Map<String, dynamic> json) {
    return CommonBarrage(
      id: _integer(json['id']),
      content: (json['content'] ?? json['text'] ?? '').toString().trim(),
    );
  }

  final int id;
  final String content;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
