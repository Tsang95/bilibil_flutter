final class FollowUser {
  const FollowUser({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    final member = json['member_obj'];
    final source = member is Map<String, dynamic>
        ? member
        : member is Map
        ? Map<String, dynamic>.from(member)
        : json;
    return FollowUser(
      id: _integer(source['id'] ?? json['member_id']),
      nickname: source['nickname']?.toString() ?? '',
      avatarUrl: source['head_sculpture']?.toString() ?? '',
    );
  }

  final int id;
  final String nickname;
  final String avatarUrl;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
