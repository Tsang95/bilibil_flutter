final class TopicSummary {
  const TopicSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.viewCount,
    required this.commentCount,
    this.lastParticipatedAt,
  });

  factory TopicSummary.fromJson(Map<String, dynamic> json) {
    return TopicSummary(
      id: _integer(json['id']),
      title: _string(json['title']),
      description: _string(json['describe']),
      viewCount: _integer(json['view_num']),
      commentCount: _integer(json['comment_num']),
      lastParticipatedAt: _dateTime(json['last_time']),
    );
  }

  final int id;
  final String title;
  final String description;
  final int viewCount;
  final int commentCount;
  final DateTime? lastParticipatedAt;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is num) return _timestamp(value.toInt());
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final timestamp = int.tryParse(text);
    if (timestamp != null) return _timestamp(timestamp);
    return DateTime.tryParse(text);
  }

  static DateTime _timestamp(int value) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.abs() >= 100000000000 ? value : value * 1000,
    );
  }
}
