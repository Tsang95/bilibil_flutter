import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/creator_data_center_models.dart';

void main() {
  test('creator data report accepts legacy numeric strings', () {
    final report = CreatorDataReport.fromJson(<String, dynamic>{
      'sum_play_num': '1200',
      'visitors_num': 90.0,
      'sum_fan_num': 88,
      'fan_increase_num': '7',
      'new_fan_num': 9,
      'fan_lost_num': '2',
      'praise_num': '18',
      'collect_num': 6,
      'coin_num': '5',
      'comment_num': 4.0,
      'barrage_num': '3',
      'gold_num': 2,
    });

    expect(report.totalPlayCount, 1200);
    expect(report.visitorCount, 90);
    expect(report.totalFanCount, 88);
    expect(report.fanIncreaseCount, 7);
    expect(report.newFanCount, 9);
    expect(report.lostFanCount, 2);
    expect(report.praiseCount, 18);
    expect(report.barrageCount, 3);
    expect(report.goldCount, 2);
  });

  test('creator chart point preserves legacy date and detail aliases', () {
    final point = CreatorChartPoint.fromJson(<String, dynamic>{
      'date': 20260825,
      'detail': '36',
    });

    expect(point.date, '20260825');
    expect(point.value, 36);
  });
}
