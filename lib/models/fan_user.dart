final class FanUser {
  const FanUser({
    required this.relationId,
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.fanCount,
    required this.lastActiveAt,
    required this.isFollowing,
  });

  factory FanUser.fromJson(Map<String, dynamic> json) {
    final rawMember = json['fan_member_obj'] ?? json['member_obj'];
    final member = rawMember is Map<String, dynamic>
        ? rawMember
        : rawMember is Map
        ? Map<String, dynamic>.from(rawMember)
        : const <String, dynamic>{};
    return FanUser(
      relationId: _integer(json['id']),
      id: _integer(member['id'] ?? json['fan_id'] ?? json['member_id']),
      nickname: member['nickname']?.toString() ?? '',
      avatarUrl: member['head_sculpture']?.toString() ?? '',
      fanCount: _integer(member['fan_num']),
      lastActiveAt: DateTime.tryParse(member['last_time']?.toString() ?? ''),
      isFollowing: _integer(json['is_force'] ?? member['is_force']) == 1,
    );
  }

  final int relationId;
  final int id;
  final String nickname;
  final String avatarUrl;
  final int fanCount;
  final DateTime? lastActiveAt;
  final bool isFollowing;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
