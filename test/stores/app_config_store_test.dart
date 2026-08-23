import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/stores/app_config_store.dart';

void main() {
  test(
    'migrates valid legacy domain and config into new storage keys',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'apiUrl': 'https://legacy.example/',
        'appConfig': jsonEncode(<String, Object>{
          'on_line': 'https://online.example',
          'share_domain': '["share.example"]',
        }),
      });

      await AppConfigStore.instance.initialize();

      expect(AppConfigStore.instance.domain, 'https://legacy.example/');
      expect(
        AppConfigStore.instance.config?.onlineUrl,
        'https://online.example',
      );
      expect(AppConfigStore.instance.config?.shareDomains, ['share.example']);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('last_successful_api_domain_v2'),
        'https://legacy.example/',
      );
      expect(preferences.getString('app_config_v2'), isNotEmpty);
    },
  );
}
