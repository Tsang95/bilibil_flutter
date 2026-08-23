final class PostBarrage {
  const PostBarrage({
    required this.id,
    required this.postId,
    required this.content,
    required this.playTime,
  });

  factory PostBarrage.fromJson(Map<String, dynamic> json) {
    return PostBarrage(
      id: _integer(json['id'] ?? json['barrage_id']),
      postId: _integer(
        json['post_content_id'] ?? json['post_id'] ?? json['postContentId'],
      ),
      content:
          (json['content'] ?? json['text'] ?? json['barrage'])
              ?.toString()
              .trim() ??
          '',
      playTime: _playTime(json),
    );
  }

  final int id;
  final int postId;
  final String content;
  final Duration playTime;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Duration _playTime(Map<String, dynamic> json) {
    final milliseconds = json['play_time_ms'] ?? json['playTimeMs'];
    if (milliseconds != null) {
      return Duration(milliseconds: _number(milliseconds).round());
    }

    final value = json['play_time'] ?? json['playTime'] ?? json['start_time'];
    if (value is String && value.contains(':')) {
      final segments = value
          .split(':')
          .map((segment) => _number(segment))
          .toList(growable: false);
      if (segments.length == 2) {
        return Duration(
          milliseconds: ((segments[0] * 60 + segments[1]) * 1000).round(),
        );
      }
      if (segments.length == 3) {
        return Duration(
          milliseconds:
              ((segments[0] * 3600 + segments[1] * 60 + segments[2]) * 1000)
                  .round(),
        );
      }
    }
    return Duration(milliseconds: (_number(value) * 1000).round());
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
