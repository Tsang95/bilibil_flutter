import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/request_cache.dart';

void main() {
  group('RequestCache', () {
    late DateTime now;
    late RequestCache cache;

    setUp(() {
      now = DateTime(2026, 8, 23, 12);
      cache = RequestCache(clock: () => now);
    });

    test('returns a fresh cached value before expiry', () {
      cache.put('guest|GET|/home', 'value', ttl: const Duration(minutes: 1));

      expect(cache.lookup('guest|GET|/home')?.value, 'value');
      expect(cache.lookup('guest|GET|/home')?.isStale, isFalse);
    });

    test('keeps stale value available only when explicitly requested', () {
      cache.put('guest|GET|/home', 'value', ttl: const Duration(seconds: 1));
      now = now.add(const Duration(seconds: 2));

      expect(cache.lookup('guest|GET|/home'), isNull);
      expect(
        cache.lookup('guest|GET|/home', includeStale: true)?.isStale,
        isTrue,
      );
    });

    test('invalidates all entries matching a write tag', () {
      cache.put(
        'guest|GET|/post/1',
        'post',
        ttl: const Duration(minutes: 1),
        tags: const {'post:1'},
      );
      cache.put(
        'guest|GET|/home',
        'home',
        ttl: const Duration(minutes: 1),
        tags: const {'home'},
      );

      cache.invalidateTags(const {'post:1'});

      expect(cache.lookup('guest|GET|/post/1'), isNull);
      expect(cache.lookup('guest|GET|/home')?.value, 'home');
    });
  });
}
