final class CreatorDataReport {
  const CreatorDataReport({
    required this.totalPlayCount,
    required this.visitorCount,
    required this.totalFanCount,
    required this.fanIncreaseCount,
    required this.newFanCount,
    required this.lostFanCount,
    required this.praiseCount,
    required this.collectCount,
    required this.coinCount,
    required this.commentCount,
    required this.barrageCount,
    required this.goldCount,
  });

  factory CreatorDataReport.fromJson(Map<String, dynamic> json) =>
      CreatorDataReport(
        totalPlayCount: _integer(json['sum_play_num']),
        visitorCount: _integer(json['visitors_num']),
        totalFanCount: _integer(json['sum_fan_num']),
        fanIncreaseCount: _integer(json['fan_increase_num']),
        newFanCount: _integer(json['new_fan_num']),
        lostFanCount: _integer(json['fan_lost_num']),
        praiseCount: _integer(json['praise_num']),
        collectCount: _integer(json['collect_num']),
        coinCount: _integer(json['coin_num']),
        commentCount: _integer(json['comment_num']),
        barrageCount: _integer(json['barrage_num']),
        goldCount: _integer(json['gold_num']),
      );

  final int totalPlayCount;
  final int visitorCount;
  final int totalFanCount;
  final int fanIncreaseCount;
  final int newFanCount;
  final int lostFanCount;
  final int praiseCount;
  final int collectCount;
  final int coinCount;
  final int commentCount;
  final int barrageCount;
  final int goldCount;
}

final class CreatorChartPoint {
  const CreatorChartPoint({required this.date, required this.value});

  factory CreatorChartPoint.fromJson(Map<String, dynamic> json) =>
      CreatorChartPoint(
        date: json['date']?.toString() ?? '',
        value: _integer(json['detail']),
      );

  final String date;
  final int value;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
