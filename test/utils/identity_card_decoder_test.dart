import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/utils/identity_card_decoder.dart';

void main() {
  test(
    'decodes identity card credentials without exposing them to storage',
    () {
      const keyValue = '12345678901234567890123456789012';
      const ivPrefix = '1234567890';
      const ivSuffix = '123456';
      final encrypted =
          Encrypter(AES(Key.fromUtf8(keyValue), mode: AESMode.cbc)).encrypt(
        'u=testAccount&p=testPassword',
        iv: IV.fromUtf8('$ivPrefix$ivSuffix'),
      );

      final credentials = IdentityCardDecoder(
        aesKey: keyValue,
        ivPrefix: ivPrefix,
        ivSuffix: ivSuffix,
      ).decode(encrypted.base64);

      expect(credentials.username, 'testAccount');
      expect(credentials.password, 'testPassword');
    },
  );

  test('identity card encoder remains readable by the legacy decoder', () {
    const keyValue = '12345678901234567890123456789012';
    const ivPrefix = '1234567890';
    const ivSuffix = '123456';
    final payload = IdentityCardEncoder(
      aesKey: keyValue,
      ivPrefix: ivPrefix,
      ivSuffix: ivSuffix,
    ).encode(username: 'test&account', password: 'p@ss=word');

    final credentials = IdentityCardDecoder(
      aesKey: keyValue,
      ivPrefix: ivPrefix,
      ivSuffix: ivSuffix,
    ).decode(payload);

    expect(credentials.username, 'test&account');
    expect(credentials.password, 'p@ss=word');
  });

  test(
    'identity card encoder can render a card without a retained password',
    () {
      const keyValue = '12345678901234567890123456789012';
      const ivPrefix = '1234567890';
      const ivSuffix = '123456';
      final payload = IdentityCardEncoder(
        aesKey: keyValue,
        ivPrefix: ivPrefix,
        ivSuffix: ivSuffix,
      ).encode(username: 'testAccount', password: '');

      expect(payload, isNotEmpty);
    },
  );
}
