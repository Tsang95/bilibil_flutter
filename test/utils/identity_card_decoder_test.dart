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
}
