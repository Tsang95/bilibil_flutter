import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/api/active_api.dart';
import 'package:b_flutter/utils/api_exception.dart';

void main() {
  test('video chunk retries transient timeouts and then succeeds', () async {
    var attempts = 0;

    final result = await ActiveApi.retryTransientUpload<String>(
      retryDelays: const <Duration>[Duration.zero, Duration.zero],
      action: () async {
        attempts++;
        if (attempts < 3) {
          throw const ApiException(
            type: ApiExceptionType.timeout,
            message: 'timeout',
          );
        }
        return 'uploaded';
      },
    );

    expect(result, 'uploaded');
    expect(attempts, 3);
  });

  test('video chunk does not retry business errors', () async {
    var attempts = 0;

    await expectLater(
      ActiveApi.retryTransientUpload<void>(
        retryDelays: const <Duration>[Duration.zero],
        action: () async {
          attempts++;
          throw const ApiException(
            type: ApiExceptionType.business,
            message: '格式不支持',
          );
        },
      ),
      throwsA(isA<ApiException>()),
    );

    expect(attempts, 1);
  });

  test('video chunk retries transient unknown transport errors', () async {
    var attempts = 0;

    final result = await ActiveApi.retryTransientUpload<String>(
      retryDelays: const <Duration>[Duration.zero],
      action: () async {
        attempts++;
        if (attempts == 1) {
          throw const ApiException(
            type: ApiExceptionType.unknown,
            message: 'transport interrupted',
          );
        }
        return 'uploaded';
      },
    );

    expect(result, 'uploaded');
    expect(attempts, 2);
  });
}
