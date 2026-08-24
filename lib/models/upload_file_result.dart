final class UploadFileResult {
  const UploadFileResult({required this.status, required this.url});

  factory UploadFileResult.fromJson(Map<String, dynamic> json) {
    return UploadFileResult(
      status: _integer(json['status']),
      url: json['url']?.toString() ?? '',
    );
  }

  final int status;
  final String url;

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
