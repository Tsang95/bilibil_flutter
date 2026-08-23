final class TopicSummary {
  const TopicSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.viewCount,
    required this.commentCount,
  });

  factory TopicSummary.fromJson(Map<String, dynamic> json) {
    return TopicSummary(
      id: _integer(json['id']),
      title: _string(json['title']),
      description: _string(json['describe']),
      viewCount: _integer(json['view_num']),
      commentCount: _integer(json['comment_num']),
    );
  }

  final int id;
  final String title;
  final String description;
  final int viewCount;
  final int commentCount;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
