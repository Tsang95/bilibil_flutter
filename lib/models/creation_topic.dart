final class CreationTopicGroup {
  const CreationTopicGroup({
    required this.id,
    required this.name,
    required this.topics,
  });

  factory CreationTopicGroup.fromJson(Map<String, dynamic> json) =>
      CreationTopicGroup(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? '',
        topics: json['topic_obj'] is List
            ? (json['topic_obj'] as List)
                  .whereType<Map>()
                  .map(
                    (item) =>
                        CreationTopic.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList(growable: false)
            : const <CreationTopic>[],
      );

  final int id;
  final String name;
  final List<CreationTopic> topics;
}

final class CreationTopic {
  const CreationTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.viewCount,
    required this.commentCount,
    required this.lastTime,
    required this.labelId,
  });

  factory CreationTopic.fromJson(Map<String, dynamic> json) => CreationTopic(
    id: _integer(json['id']),
    title: json['title']?.toString() ?? '',
    description: json['describe']?.toString() ?? '',
    viewCount: _integer(json['view_num']),
    commentCount: _integer(json['comment_num']),
    lastTime: json['last_time']?.toString() ?? '',
    labelId: _integer(json['label_id']),
  );

  final int id;
  final String title;
  final String description;
  final int viewCount;
  final int commentCount;
  final String lastTime;
  final int labelId;
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
