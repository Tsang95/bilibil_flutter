import 'package:encrypt/encrypt.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/utils/api_exception.dart';

final class IdentityCredentials {
  const IdentityCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

final class IdentityCardDecoder {
  IdentityCardDecoder({String? aesKey, String? ivPrefix, String? ivSuffix})
    : _aesKey = aesKey ?? AppEnvironment.apiResponseAesKey,
      _ivPrefix = ivPrefix ?? AppEnvironment.apiResponseIvPrefix,
      _ivSuffix = ivSuffix ?? AppEnvironment.identityCardIvSuffix;

  final String _aesKey;
  final String _ivPrefix;
  final String _ivSuffix;

  IdentityCredentials decode(String payload) {
    if (payload.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.parsing,
        message: '未识别到有效身份卡',
      );
    }
    if (_aesKey.isEmpty || _ivPrefix.isEmpty || _ivSuffix.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.parsing,
        message: '身份卡解密配置缺失',
      );
    }

    try {
      final encrypter = Encrypter(
        AES(Key.fromUtf8(_aesKey), mode: AESMode.cbc),
      );
      final plaintext = encrypter.decrypt64(
        payload,
        iv: IV.fromUtf8('$_ivPrefix$_ivSuffix'),
      );
      final parameters = Uri.parse(
        'identity://local/?$plaintext',
      ).queryParameters;
      final username = parameters['u']?.trim() ?? '';
      final password = parameters['p'] ?? '';
      if (username.isEmpty || password.isEmpty) {
        throw const FormatException('Missing identity credentials');
      }
      return IdentityCredentials(username: username, password: password);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        type: ApiExceptionType.parsing,
        message: '身份卡内容无效',
        cause: error,
      );
    }
  }
}

final class IdentityCardEncoder {
  IdentityCardEncoder({String? aesKey, String? ivPrefix, String? ivSuffix})
    : _aesKey = aesKey ?? AppEnvironment.apiResponseAesKey,
      _ivPrefix = ivPrefix ?? AppEnvironment.apiResponseIvPrefix,
      _ivSuffix = ivSuffix ?? AppEnvironment.identityCardIvSuffix;

  final String _aesKey;
  final String _ivPrefix;
  final String _ivSuffix;

  String encode({required String username, required String password}) {
    if (username.trim().isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.parsing,
        message: '未识别到有效身份卡凭证',
      );
    }
    if (_aesKey.isEmpty || _ivPrefix.isEmpty || _ivSuffix.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.parsing,
        message: '身份卡加密配置缺失',
      );
    }
    try {
      final query = Uri(
        queryParameters: <String, String>{'u': username.trim(), 'p': password},
      ).query;
      return Encrypter(
        AES(Key.fromUtf8(_aesKey), mode: AESMode.cbc),
      ).encrypt(query, iv: IV.fromUtf8('$_ivPrefix$_ivSuffix')).base64;
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        type: ApiExceptionType.parsing,
        message: '身份卡生成失败',
        cause: error,
      );
    }
  }
}
