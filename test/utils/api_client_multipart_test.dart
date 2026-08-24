import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/api_client.dart';

void main() {
  test('multipart request metadata can be used in a cache key', () {
    final form = FormData.fromMap(<String, Object?>{
      'file': MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'cover.png'),
    });

    final key = ApiClient().buildCacheKey(
      method: 'POST',
      path: 'api/uploads',
      data: form,
    );

    expect(key, contains('cover.png'));
    expect(key, contains('3'));
  });
}
