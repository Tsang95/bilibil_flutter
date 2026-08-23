final class SearchUser {
  const SearchUser({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.movieLevel,
    required this.fanCount,
    required this.workCount,
    required this.isFollowing,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: _integer(json['id']),
      nickname: _string(json['nickname']),
      avatarUrl: _string(json['head_sculpture']),
      movieLevel: _integer(json['movie_level']),
      fanCount: _integer(json['fan_num']),
      workCount: _integer(json['work_num']),
      isFollowing: _integer(json['is_force'] ?? json['isForce']) == 1,
    );
  }

  final int id;
  final String nickname;
  final String avatarUrl;
  final int movieLevel;
  final int fanCount;
  final int workCount;
  final bool isFollowing;

  SearchUser copyWith({bool? isFollowing}) {
    return SearchUser(
      id: id,
      nickname: nickname,
      avatarUrl: avatarUrl,
      movieLevel: movieLevel,
      fanCount: fanCount,
      workCount: workCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
