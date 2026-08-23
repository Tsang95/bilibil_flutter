import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/app_version.dart';
import 'package:b_flutter/models/suggestion_reason.dart';

void main() {
  test('AppVersion parses legacy version fields and numeric aliases', () {
    final version = AppVersion.fromJson(<String, dynamic>{
      'id': '8',
      'title': '升级提示',
      'describe': '修复问题',
      'version_no': '12',
      'is_force': '1',
      'down_url': 'https://example.com/app.apk',
    });

    expect(version.id, 8);
    expect(version.versionNumber, 12);
    expect(version.isForced, isTrue);
    expect(version.downloadUrl, 'https://example.com/app.apk');
  });

  test('SuggestionReason accepts legacy identifier and name', () {
    final reason = SuggestionReason.fromJson(<String, dynamic>{
      'id': '3',
      'name': '播放问题',
    });

    expect(reason.id, 3);
    expect(reason.name, '播放问题');
  });
}
