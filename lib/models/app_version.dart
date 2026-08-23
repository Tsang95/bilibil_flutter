final class AppVersion {
  const AppVersion({
    required this.id,
    required this.title,
    required this.description,
    required this.versionNumber,
    required this.isForce,
    required this.downloadUrl,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: _integer(json['id']),
      title: _string(json['title']),
      description: _string(json['describe']),
      versionNumber: _integer(json['version_no']),
      isForce: _integer(json['is_force']),
      downloadUrl: _string(json['down_url']),
    );
  }

  final int id;
  final String title;
  final String description;
  final int versionNumber;
  final int isForce;
  final String downloadUrl;

  bool get isForced => isForce != 0;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
