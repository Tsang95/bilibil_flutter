final class GameCategory {
  const GameCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.games,
  });

  factory GameCategory.fromJson(Map<String, dynamic> json) {
    final children = json['child'];
    return GameCategory(
      id: _integer(json['id']),
      name: json['name']?.toString() ?? '',
      iconUrl: json['thumb']?.toString() ?? '',
      games: children is List
          ? children
                .whereType<Map>()
                .map(
                  (item) => GameItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <GameItem>[],
    );
  }

  final int id;
  final String name;
  final String iconUrl;
  final List<GameItem> games;
}

final class GameItem {
  const GameItem({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
    id: _integer(json['id']),
    name: json['name']?.toString() ?? '',
    thumbnailUrl: json['thumb']?.toString() ?? '',
  );

  final int id;
  final String name;
  final String thumbnailUrl;
}

final class GameActivity {
  const GameActivity({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.startTime,
    required this.endTime,
    required this.html,
  });

  factory GameActivity.fromJson(Map<String, dynamic> json) => GameActivity(
    id: _integer(json['id']),
    title: json['title']?.toString() ?? '',
    thumbnailUrl: json['thumb']?.toString() ?? '',
    startTime: _integer(json['start_time']),
    endTime: _integer(json['end_time']),
    html: json['content']?.toString() ?? '',
  );

  final int id;
  final String title;
  final String thumbnailUrl;
  final int startTime;
  final int endTime;
  final String html;
}

final class GameLaunch {
  const GameLaunch({
    required this.url,
    required this.showType,
    required this.platformId,
  });

  factory GameLaunch.fromJson(Map<String, dynamic> json) => GameLaunch(
    url: json['jump_url']?.toString() ?? '',
    showType: _integer(json['show_type']),
    platformId: _integer(json['platform_id']),
  );

  final String url;
  final int showType;
  final int platformId;

  bool get isLandscape => showType == 2;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
