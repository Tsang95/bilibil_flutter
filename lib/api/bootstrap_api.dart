import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/app_config.dart';
import 'package:b_flutter/utils/api_client.dart';

abstract final class BootstrapApi {
  static Future<List<String>> getDomains() {
    return ApiClient().get<List<String>>(
      'api/androidDomainLists',
      data: const <String, Object?>{},
      parser: (data) {
        if (data is! List) return const <String>[];
        return data
            .map((item) => item.toString().trim())
            .where((domain) => domain.isNotEmpty)
            .toList(growable: false);
      },
      deduplicate: true,
    );
  }

  static Future<AppConfig> getConfig() {
    return ApiClient().get<AppConfig>(
      'api/sysConfigs',
      data: const <String, Object?>{'channel': AppEnvironment.channel},
      parser: (data) {
        if (data is! Map) {
          throw const FormatException('Invalid app config');
        }
        return AppConfig.fromJson(Map<String, dynamic>.from(data));
      },
      deduplicate: true,
    );
  }
}
