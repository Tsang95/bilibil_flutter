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
      lastActiveAt: _dateTime(member['last_time']),
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

DateTime? _dateTime(Object? value) {
  if (value is num) return _timestamp(value.toInt());
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final timestamp = int.tryParse(text);
  if (timestamp != null) return _timestamp(timestamp);
  return DateTime.tryParse(text);
}

DateTime _timestamp(int value) => DateTime.fromMillisecondsSinceEpoch(
  value.abs() >= 100000000000 ? value : value * 1000,
);
