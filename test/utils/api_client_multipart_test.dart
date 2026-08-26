import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/request_cache.dart';

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

  test('cache keys retain values from maps with non-string keys', () {
    final key = ApiClient().buildCacheKey(
      method: 'GET',
      path: 'api/example',
      data: <Object, Object?>{1: 'numeric-key-value'},
    );

    expect(key, contains('numeric-key-value'));
  });

  test('a parser failure is never written into request cache', () async {
    final cache = RequestCache();
    final adapter = _StaticAdapter(<String, Object?>{
      'code': 200,
      'data': <String, Object?>{'unexpected': true},
    });
    final client = _client(adapter: adapter, cache: cache);

    await expectLater(
      client.get<String>(
        'api/example',
        parser: (_) => throw const FormatException('invalid payload'),
        cachePolicy: const CachePolicy.cacheFirst(),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiExceptionType.parsing,
        ),
      ),
    );

    expect(cache.length, 0);
  });

  test(
    'a parser failure does not invalidate successful cached reads',
    () async {
      final cache = RequestCache();
      cache.put(
        'existing',
        'value',
        ttl: const Duration(minutes: 1),
        tags: const <String>{'history'},
      );
      final client = _client(
        adapter: _StaticAdapter(<String, Object?>{
          'code': 200,
          'data': <String, Object?>{'unexpected': true},
        }),
        cache: cache,
      );

      await expectLater(
        client.post<void>(
          'api/write',
          parser: (_) => throw const FormatException('invalid payload'),
          invalidateCacheTags: const <String>{'history'},
        ),
        throwsA(isA<ApiException>()),
      );

      expect(cache.lookup('existing')?.value, 'value');
    },
  );

  test('an incompatible fresh cache entry is evicted and retried', () async {
    final cache = RequestCache();
    final adapter = _StaticAdapter(<String, Object?>{
      'code': 200,
      'data': <String, Object?>{'value': 'network'},
    });
    final client = _client(adapter: adapter, cache: cache);
    final key = client.buildCacheKey(method: 'GET', path: 'api/example');
    cache.put(key, <String, Object?>{
      'invalid': true,
    }, ttl: const Duration(minutes: 1));

    final result = await client.get<String>(
      'api/example',
      parser: (data) {
        if (data is! Map || data['value'] is! String) {
          throw const FormatException('missing value');
        }
        return data['value'] as String;
      },
      cachePolicy: const CachePolicy.cacheFirst(),
    );

    expect(result, 'network');
    expect(adapter.callCount, 1);
  });
}

ApiClient _client({
  required _StaticAdapter adapter,
  required RequestCache cache,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/',
      responseType: ResponseType.json,
    ),
  )..httpClientAdapter = adapter;
  return ApiClient.forTesting(dio: dio, cache: cache);
}

final class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter(this.body);

  final Object? body;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
