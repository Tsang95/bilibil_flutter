import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/stores/app_config_store.dart';

abstract final class VideoUrlResolver {
  static String resolve(
    String value, {
    String? signingKey,
    int? timestampSeconds,
  }) {
    final normalizedUrl = _absoluteUrl(value);
    if (normalizedUrl.isEmpty) return '';
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return '';
    if (uri.queryParameters.containsKey('wsSecret')) return uri.toString();

    final key = signingKey ?? AppEnvironment.videoSigningKey;
    if (key.isEmpty) return uri.toString();
    final timestamp =
        timestampSeconds ??
        DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    final normalizedPath = uri.path.replaceAll(RegExp('/+'), '/');
    final signature = md5
        .convert(utf8.encode('$key$normalizedPath$timestamp'))
        .toString();
    return uri
        .replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            'wsSecret': signature,
            'wsTime': '$timestamp',
          },
        )
        .toString();
  }

  static String _absoluteUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('http')) return trimmed;
    final config = AppConfigStore.instance.config;
    final baseUrl = config?.videoBaseUrl.isNotEmpty == true
        ? config!.videoBaseUrl
        : config?.sourceBaseUrl ?? '';
    if (baseUrl.isEmpty) return trimmed;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.tryParse(normalizedBase)?.resolve(trimmed).toString() ?? trimmed;
  }
}
