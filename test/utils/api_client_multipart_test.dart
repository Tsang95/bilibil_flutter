import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/api_client.dart';

void main() {
  test('multipart request metadata can be used in a cache key', () {
    final form = FormData.fromMap(<String, Object?>{
      'chunk': MultipartFile.fromBytes(<int>[1, 2, 3], filename: 'video.mp4'),
      'filename': 'video.mp4',
      'chunked': true,
      'chunkNumber': 1,
      'totalChunks': 3,
    });

    final key = ApiClient().buildCacheKey(
      method: 'POST',
      path: 'api/uploads',
      data: form,
    );

    expect(key, contains('video.mp4'));
    expect(key, contains('3'));
    expect(key, contains('chunkNumber'));
    expect(key, contains('totalChunks'));
  });
}
