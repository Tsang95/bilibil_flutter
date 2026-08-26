String formatLegacyCompactCount(int value) {
  if (value > 1000000) {
    return '${(value / 10000).toStringAsFixed(1)} 百万';
  }
  if (value > 10000) {
    return '${(value / 10000).toStringAsFixed(1)} w';
  }
  if (value > 1000) {
    final divided = value / 1000;
    final text = value % 1000 == 0
        ? divided.toStringAsFixed(0)
        : divided.toStringAsFixed(1);
    return '$text k';
  }
  return '$value';
}

String formatLegacyDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(duration.inHours)}:'
      '${twoDigits(duration.inMinutes.remainder(60))}:'
      '${twoDigits(duration.inSeconds.remainder(60))}';
}

String formatLegacyRelativeTime(DateTime? value, {DateTime? now}) {
  if (value == null) return '';
  final localValue = value.toLocal();
  final difference = localValue.difference(now?.toLocal() ?? DateTime.now());
  final minutes = difference.inMinutes.abs();
  if (minutes < 5) return '刚刚';
  if (minutes < 60) return '$minutes分钟之前';

  final hours = difference.inHours.abs();
  if (hours < 24) return '$hours小时之前';

  final days = difference.inDays.abs();
  if (days < 7) return '$days天前';
  if (days >= 7 && days < 8) return '1周前';
  if (days > 8 && days < 30) return '$days天前';
  return '${localValue.year.toString().padLeft(4, '0')}-'
      '${localValue.month.toString().padLeft(2, '0')}-'
      '${localValue.day.toString().padLeft(2, '0')}';
}
