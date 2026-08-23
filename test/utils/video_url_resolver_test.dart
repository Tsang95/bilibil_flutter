import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/video_url_resolver.dart';

void main() {
  test('keeps an already signed video URL unchanged', () {
    const url =
        'https://video.example.test/a/b.mp4?quality=hd&wsSecret=ready&wsTime=1';

    expect(
      VideoUrlResolver.resolve(url, signingKey: 'unused', timestampSeconds: 9),
      url,
    );
  });

  test('adds deterministic signature without discarding query parameters', () {
    final result = VideoUrlResolver.resolve(
      'https://video.example.test/a//b.mp4?quality=hd',
      signingKey: 'test-only-signing-key',
      timestampSeconds: 100,
    );
    final uri = Uri.parse(result);

    expect(uri.queryParameters['quality'], 'hd');
    expect(uri.queryParameters['wsTime'], '100');
    expect(uri.queryParameters['wsSecret'], hasLength(32));
  });

  test('returns an unsigned URL when no signing key is supplied', () {
    const url = 'https://video.example.test/movie.mp4?quality=sd';

    expect(VideoUrlResolver.resolve(url, signingKey: ''), url);
  });
}
