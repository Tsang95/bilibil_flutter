class TaskSignReward {
  const TaskSignReward({
    required this.id,
    required this.name,
    required this.day,
    required this.tips,
    required this.isToday,
  });

  final int id;
  final String name;
  final String day;
  final String tips;
  final bool isToday;

  bool get isSigned => tips == '已签到';

  factory TaskSignReward.fromJson(Map<String, dynamic> json) {
    return TaskSignReward(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      tips: json['tips']?.toString() ?? '',
      isToday: _asInt(json['today']) == 1,
    );
  }
}

class DailyTaskSummary {
  const DailyTaskSummary({required this.isSigned, required this.rewards});

  final bool isSigned;
  final List<TaskSignReward> rewards;

  TaskSignReward? get todayReward {
    for (final reward in rewards) {
      if (reward.isToday) return reward;
    }
    return null;
  }

  factory DailyTaskSummary.fromJson(Map<String, dynamic> json) {
    final rawRewards = json['sign_goods'];
    return DailyTaskSummary(
      isSigned: _asInt(json['is_sign']) == 1,
      rewards: rawRewards is List
          ? rawRewards
                .whereType<Map>()
                .map(
                  (item) =>
                      TaskSignReward.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <TaskSignReward>[],
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.rule,
    required this.status,
  });

  final int id;
  final String title;
  final String rule;
  final int status;

  bool get isComplete => status == 1;
  bool get canComplete => status == 0;
  bool get isActionable => !isComplete;

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: _asInt(json['id']),
    title: json['title']?.toString() ?? '',
    rule: json['rule']?.toString() ?? '',
    status: _asInt(json['status']),
  );
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
