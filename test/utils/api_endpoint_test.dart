import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/api_endpoint.dart';

void main() {
  test('preserves the legacy api base path and adds a trailing slash', () {
    expect(
      ApiEndpoint.normalizeBaseUrl('https://example.com/api'),
      'https://example.com/api/',
    );
  });

  test('normalizes a host-only seed without duplicating query data', () {
    expect(
      ApiEndpoint.normalizeBaseUrl('example.com?source=debug'),
      'https://example.com/',
    );
  });
}
