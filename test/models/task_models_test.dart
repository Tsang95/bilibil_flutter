import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/task_models.dart';

void main() {
  test('daily task models retain legacy sign fields and aliases', () {
    final summary = DailyTaskSummary.fromJson(<String, dynamic>{
      'is_sign': '0',
      'sign_goods': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '2',
          'name': '5金币',
          'day': '第2天',
          'tips': '已签到',
          'today': 1,
        },
      ],
    });

    expect(summary.isSigned, isFalse);
    expect(summary.todayReward?.id, 2);
    expect(summary.rewards.single.isSigned, isTrue);
  });

  test('task item exposes legacy completion states', () {
    expect(
      TaskItem.fromJson(<String, dynamic>{'id': 1, 'status': 0}).canComplete,
      isTrue,
    );
    expect(
      TaskItem.fromJson(<String, dynamic>{'id': 1, 'status': 1}).isComplete,
      isTrue,
    );
    expect(
      TaskItem.fromJson(<String, dynamic>{'id': 1, 'status': 2}).isActionable,
      isTrue,
    );
  });
}
