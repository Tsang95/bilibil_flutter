final class GoogleVerifyData {
  const GoogleVerifyData({required this.key, required this.url});

  factory GoogleVerifyData.fromJson(Map<String, dynamic> json) =>
      GoogleVerifyData(
        key: json['key']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
      );

  final String key;
  final String url;
}
