final class InviteSummary {
  const InviteSummary({
    required this.shareDomains,
    required this.invitedCount,
    required this.rewardCoins,
  });

  factory InviteSummary.fromJson(Map<String, dynamic> json) {
    return InviteSummary(
      shareDomains: _domains(json['share_domain']),
      invitedCount: _integer(json['share_member_num']),
      rewardCoins: _integer(json['share_sum_coin']),
    );
  }

  final List<String> shareDomains;
  final int invitedCount;
  final int rewardCoins;

  static List<String> _domains(Object? value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return value
        .toString()
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
