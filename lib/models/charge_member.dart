final class ChargeMember {
  const ChargeMember({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.subscriptionDays,
  });

  factory ChargeMember.fromJson(Map<String, dynamic> json) {
    return ChargeMember(
      id: _integer(json['id']),
      nickname: (json['nickname'] ?? '').toString().trim(),
      avatarUrl: (json['head_sculpture'] ?? '').toString().trim(),
      subscriptionDays: _integer(json['is_sub']),
    );
  }

  final int id;
  final String nickname;
  final String avatarUrl;
  final int subscriptionDays;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
