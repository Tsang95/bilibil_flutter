final class HelpItem {
  const HelpItem({
    required this.id,
    required this.title,
    required this.content,
  });

  factory HelpItem.fromJson(Map<String, dynamic> json) => HelpItem(
    id: _integer(json['id']),
    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
  );

  final int id;
  final String title;
  final String content;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
