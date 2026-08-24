import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';

import 'package:b_flutter/common/app_environment.dart';

/// Compatibility adapter for the legacy backend wire protocol.
///
/// Protocol secrets are injected at build time and never have source-code
/// defaults. This preserves backend compatibility without carrying the legacy
/// project's plaintext credentials into the refactor.
final class LegacyProtocolInterceptor extends Interceptor {
  LegacyProtocolInterceptor({
    String? signingKey,
    String? responseAesKey,
    String? responseIvPrefix,
  }) : _signingKey = signingKey ?? AppEnvironment.apiSigningKey,
       _responseAesKey = responseAesKey ?? AppEnvironment.apiResponseAesKey,
       _responseIvPrefix =
           responseIvPrefix ?? AppEnvironment.apiResponseIvPrefix;

  final String _signingKey;
  final String _responseAesKey;
  final String _responseIvPrefix;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_signingKey.isNotEmpty) {
      final timestamp = DateTime.now().second;
      final source = '$timestamp${options.path}${options.method}$_signingKey'
          .replaceAll('api/api/', 'api/');
      options.headers['timestamp'] = timestamp;
      options.headers['sign'] = md5.convert(utf8.encode(source)).toString();
    }
    if (options.data is FormData) {
      options.headers[Headers.contentTypeHeader] = 'multipart/form-data';
    } else {
      options.headers[Headers.contentTypeHeader] = Headers.jsonContentType;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    try {
      final decodedBody = _decodeJsonIfNeeded(response.data);
      if (decodedBody is Map) {
        final body = Map<String, dynamic>.from(decodedBody);
        final encryptedEnvelope = body['data'];
        if (encryptedEnvelope is Map &&
            encryptedEnvelope['suffix'] is String &&
            encryptedEnvelope['data'] is String) {
          body['data'] = _decryptPayload(
            encryptedEnvelope['data'] as String,
            encryptedEnvelope['suffix'] as String,
          );
        }
        response.data = body;
      } else {
        response.data = decodedBody;
      }
      handler.next(response);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: '响应数据解密或解析失败',
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }

  Object? _decodeJsonIfNeeded(Object? value) {
    if (value is! String) return value;
    return jsonDecode(value);
  }

  Object? _decryptPayload(String encryptedData, String suffix) {
    if (_responseAesKey.isEmpty || _responseIvPrefix.isEmpty) {
      throw StateError('响应解密密钥未配置');
    }
    final ivValue = '$_responseIvPrefix$suffix';
    final encrypter = Encrypter(
      AES(Key.fromUtf8(_responseAesKey), mode: AESMode.cbc),
    );
    final plaintext = encrypter.decrypt64(
      encryptedData,
      iv: IV.fromUtf8(ivValue),
    );
    return jsonDecode(plaintext);
  }
}
