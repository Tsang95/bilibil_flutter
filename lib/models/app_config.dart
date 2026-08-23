import 'dart:convert';

final class AppConfig {
  const AppConfig({
    required this.onlineUrl,
    required this.sourceBaseUrl,
    required this.uploadVideoUrl,
    required this.videoBaseUrl,
    required this.withdrawalFee,
    required this.usdtExchangeRate,
    required this.telegramGroup,
    required this.businessContact,
    required this.shareDomains,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      onlineUrl: _string(json['on_line']),
      sourceBaseUrl: _string(json['source_base_url']),
      uploadVideoUrl: _string(json['up_video_m3u8']),
      videoBaseUrl: _string(json['video_base_url']),
      withdrawalFee: _number(json['withdrawal_fee']),
      usdtExchangeRate: _number(json['usdt_exchange_rate']),
      telegramGroup: _string(json['telegram_group']),
      businessContact: _string(json['business_connect']),
      shareDomains: _stringList(json['share_domain']),
    );
  }

  final String onlineUrl;
  final String sourceBaseUrl;
  final String uploadVideoUrl;
  final String videoBaseUrl;
  final double withdrawalFee;
  final double usdtExchangeRate;
  final String telegramGroup;
  final String businessContact;
  final List<String> shareDomains;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'on_line': onlineUrl,
      'source_base_url': sourceBaseUrl,
      'up_video_m3u8': uploadVideoUrl,
      'video_base_url': videoBaseUrl,
      'withdrawal_fee': withdrawalFee,
      'usdt_exchange_rate': usdtExchangeRate,
      'telegram_group': telegramGroup,
      'business_connect': businessContact,
      'share_domain': shareDomains,
    };
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(Object? value) {
    Object? decoded = value;
    if (value is String && value.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(value);
      } on FormatException {
        return const <String>[];
      }
    }
    if (decoded is! List) return const <String>[];
    return decoded
        .map(_string)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
