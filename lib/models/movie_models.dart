final class MovieKeywordItem {
  const MovieKeywordItem({required this.id, required this.keyword});

  factory MovieKeywordItem.fromJson(Map<String, dynamic> json) {
    return MovieKeywordItem(
      id: _integer(json['id']),
      keyword: _string(json['keyword']),
    );
  }

  final int id;
  final String keyword;
}

final class MovieKeywordGroup {
  const MovieKeywordGroup({
    required this.id,
    required this.parentId,
    required this.keyword,
    required this.children,
  });

  factory MovieKeywordGroup.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['son_keyword'];
    return MovieKeywordGroup(
      id: _integer(json['id']),
      parentId: _integer(json['p_id']),
      keyword: _string(json['keyword']),
      children: rawChildren is List
          ? rawChildren
              .whereType<Map>()
              .map(
                (item) => MovieKeywordItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <MovieKeywordItem>[],
    );
  }

  final int id;
  final int parentId;
  final String keyword;
  final List<MovieKeywordItem> children;
}

final class MovieActorWork {
  const MovieActorWork({
    required this.id,
    required this.coverUrls,
    required this.title,
    required this.isVipOnly,
  });

  factory MovieActorWork.fromJson(Map<String, dynamic> json) {
    return MovieActorWork(
      id: _integer(json['id']),
      coverUrls: _stringList(json['cover_images']),
      title: _string(json['title']),
      isVipOnly: _integer(json['is_vip_watch']) == 1,
    );
  }

  final int id;
  final List<String> coverUrls;
  final String title;
  final bool isVipOnly;

  String get coverUrl => coverUrls.isEmpty ? '' : coverUrls.first;
}

final class MovieActorGroup {
  const MovieActorGroup({
    required this.id,
    required this.name,
    required this.workCount,
    required this.works,
  });

  factory MovieActorGroup.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['post_obj'];
    return MovieActorGroup(
      id: _integer(json['id']),
      name: _string(json['name']),
      workCount: _integer(json['post_number']),
      works: rawWorks is List
          ? rawWorks
              .whereType<Map>()
              .map(
                (item) =>
                    MovieActorWork.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const <MovieActorWork>[],
    );
  }

  final int id;
  final String name;
  final int workCount;
  final List<MovieActorWork> works;
}

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map(_string)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
