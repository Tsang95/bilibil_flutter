import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/api_endpoint.dart';
import 'package:b_flutter/utils/logger_util.dart';
import 'package:b_flutter/utils/legacy_protocol_interceptor.dart';
import 'package:b_flutter/utils/request_cache.dart';
import 'package:b_flutter/utils/request_lock.dart';
import 'package:b_flutter/utils/toast.dart';

typedef ApiParser<T> = T Function(Object? data);

final class ApiClient {
  ApiClient._({Dio? dio, RequestCache? cache, RequestLockManager? lockManager})
    : _dio = dio ?? _buildDio(),
      _cache = cache ?? RequestCache.instance,
      _lockManager = lockManager ?? RequestLockManager.instance {
    _installInterceptors();
  }

  static final ApiClient instance = ApiClient._();

  factory ApiClient() => instance;

  final Dio _dio;
  final RequestCache _cache;
  final RequestLockManager _lockManager;
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};

  Dio get dio => _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
  }

  void _installInterceptors() {
    _dio.interceptors.add(LegacyProtocolInterceptor());
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['channel'] = AppEnvironment.channel;
          final token = TokenManager.instance.token;
          if (token.isEmpty) {
            options.headers.remove('token');
          } else {
            options.headers['token'] = token;
          }
          handler.next(options);
        },
      ),
    );
  }

  void configureBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim();
    if (normalized.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.connection,
        message: 'API 地址未配置',
      );
    }
    _dio.options.baseUrl = ApiEndpoint.normalizeBaseUrl(normalized);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    required ApiParser<T> parser,
    CachePolicy cachePolicy = const CachePolicy.disabled(),
    Set<String> cacheTags = const <String>{},
    bool lock = false,
    String lockText = '加载中...',
    bool showErrorToast = false,
    bool deduplicate = true,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      data: data,
      parser: parser,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      lock: lock,
      lockText: lockText,
      showErrorToast: showErrorToast,
      deduplicate: deduplicate,
      cancelToken: cancelToken,
    );
  }

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    required ApiParser<T> parser,
    CachePolicy cachePolicy = const CachePolicy.disabled(),
    Set<String> cacheTags = const <String>{},
    Set<String> invalidateCacheTags = const <String>{},
    bool lock = false,
    String lockText = '提交中...',
    bool showErrorToast = false,
    bool deduplicate = false,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      method: 'POST',
      queryParameters: queryParameters,
      data: data,
      parser: parser,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      invalidateCacheTags: invalidateCacheTags,
      lock: lock,
      lockText: lockText,
      showErrorToast: showErrorToast,
      deduplicate: deduplicate,
      cancelToken: cancelToken,
    );
  }

  Future<T> request<T>(
    String path, {
    required String method,
    Map<String, dynamic>? queryParameters,
    Object? data,
    required ApiParser<T> parser,
    CachePolicy cachePolicy = const CachePolicy.disabled(),
    Set<String> cacheTags = const <String>{},
    Set<String> invalidateCacheTags = const <String>{},
    bool lock = false,
    String lockText = '加载中...',
    bool showErrorToast = false,
    bool deduplicate = true,
    CancelToken? cancelToken,
  }) async {
    final normalizedMethod = method.toUpperCase();
    final cacheKey = buildCacheKey(
      method: normalizedMethod,
      path: path,
      queryParameters: queryParameters,
      data: data,
    );

    if (cachePolicy.mode == CacheMode.cacheFirst) {
      final cached = _cache.lookup(cacheKey);
      if (cached != null) return _parse(parser, cached.value);
    }

    Future<Object?> networkAction() {
      if (!deduplicate) {
        return _performRequest(
          path,
          method: normalizedMethod,
          queryParameters: queryParameters,
          data: data,
          cancelToken: cancelToken,
        );
      }

      final existing = _inFlight[cacheKey];
      if (existing != null) return existing;

      late final Future<Object?> requestFuture;
      requestFuture =
          _performRequest(
            path,
            method: normalizedMethod,
            queryParameters: queryParameters,
            data: data,
            cancelToken: cancelToken,
          ).whenComplete(() {
            if (identical(_inFlight[cacheKey], requestFuture)) {
              _inFlight.remove(cacheKey);
            }
          });
      _inFlight[cacheKey] = requestFuture;
      return requestFuture;
    }

    try {
      final rawData = lock
          ? await _lockManager.runLocked(networkAction, message: lockText)
          : await networkAction();

      if (cachePolicy.enabled) {
        _cache.put(cacheKey, rawData, ttl: cachePolicy.ttl, tags: cacheTags);
      }
      if (invalidateCacheTags.isNotEmpty) {
        _cache.invalidateTags(invalidateCacheTags);
      }
      return _parse(parser, rawData);
    } catch (error, stackTrace) {
      if (cachePolicy.allowStaleOnError) {
        final stale = _cache.lookup(cacheKey, includeStale: true);
        if (stale != null) {
          logger.w('请求失败，使用过期缓存: $path', error: error);
          return _parse(parser, stale.value);
        }
      }

      final exception = _mapException(error);
      logger.e(
        'API 请求失败 [$normalizedMethod] $path',
        error: _safeDiagnostic(error, exception),
        stackTrace: stackTrace,
      );
      if (showErrorToast) {
        showToast(exception.message, type: ToastType.error);
      }
      throw exception;
    }
  }

  Future<Object?> _performRequest(
    String path, {
    required String method,
    Map<String, dynamic>? queryParameters,
    Object? data,
    CancelToken? cancelToken,
  }) async {
    if (_dio.options.baseUrl.isEmpty && !path.startsWith('http')) {
      final domains = AppEnvironment.configuredApiDomains;
      if (domains.isEmpty) {
        throw const ApiException(
          type: ApiExceptionType.connection,
          message: 'API 域名尚未配置',
        );
      }
      configureBaseUrl(ApiEndpoint.normalizeBaseUrl(domains.first));
    }

    final response = await _dio.request<Object?>(
      _normalizePath(path),
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(method: method),
    );
    return _unwrapResponse(response);
  }

  Object? _unwrapResponse(Response<Object?> response) {
    final body = response.data;
    if (body is! Map) return body;

    final map = Map<String, dynamic>.from(body);
    final code = map['code'];
    final numericCode = code is int ? code : int.tryParse('$code');
    if (numericCode == 401) {
      throw ApiException(
        type: ApiExceptionType.unauthorized,
        message: _responseMessage(map, fallback: '登录状态已失效'),
        statusCode: numericCode,
      );
    }
    if (numericCode != null && numericCode != 200 && numericCode != 1) {
      throw ApiException(
        type: ApiExceptionType.business,
        message: _responseMessage(map, fallback: '请求失败'),
        statusCode: numericCode,
      );
    }
    return map.containsKey('data') ? map['data'] : map;
  }

  String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message'] ?? response['msg'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : fallback;
  }

  T _parse<T>(ApiParser<T> parser, Object? data) {
    try {
      return parser(data);
    } catch (error) {
      throw ApiException(
        type: ApiExceptionType.parsing,
        message: '数据解析失败',
        cause: error,
      );
    }
  }

  ApiException _mapException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (error.type == DioExceptionType.badResponse) {
        final protocolMessage = error.error?.toString() ?? '';
        if (protocolMessage.contains('解密') || protocolMessage.contains('解析')) {
          return ApiException(
            type: ApiExceptionType.parsing,
            message: '服务器数据解析失败，请稍后重试',
            statusCode: statusCode,
            cause: error,
          );
        }
        return ApiException(
          type: statusCode == 401
              ? ApiExceptionType.unauthorized
              : ApiExceptionType.business,
          message: switch (statusCode) {
            401 => '登录状态已失效',
            404 => '请求地址不存在，请检查线路配置',
            final int code when code >= 500 => '服务器暂时不可用，请稍后重试',
            _ => '服务器返回异常，请稍后重试',
          },
          statusCode: statusCode,
          cause: error,
        );
      }
      final type = switch (error.type) {
        DioExceptionType.cancel => ApiExceptionType.cancelled,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ApiExceptionType.timeout,
        DioExceptionType.connectionError => ApiExceptionType.connection,
        DioExceptionType.badCertificate => ApiExceptionType.connection,
        _ when _isConnectionFailure(error.error) => ApiExceptionType.connection,
        _ => ApiExceptionType.unknown,
      };
      return ApiException(
        type: type,
        message: switch (type) {
          ApiExceptionType.cancelled => '请求已取消',
          ApiExceptionType.timeout => '网络连接超时，请稍后重试',
          ApiExceptionType.connection => '网络连接失败，请检查网络',
          _ => '服务器异常，请稍后重试',
        },
        statusCode: statusCode,
        cause: error,
      );
    }
    return ApiException(
      type: ApiExceptionType.unknown,
      message: '操作失败，请稍后重试',
      cause: error,
    );
  }

  bool _isConnectionFailure(Object? cause) {
    return cause is SocketException ||
        cause is HttpException ||
        cause is HandshakeException;
  }

  Object _safeDiagnostic(Object error, ApiException exception) {
    if (error is! DioException) return exception;
    final statusCode = error.response?.statusCode;
    final cause = error.error;
    final causeType = cause?.runtimeType;
    final causeMessage = switch (cause) {
      HttpException() => cause.message,
      _ => null,
    };
    return 'DioException('
        'type: ${error.type.name}, '
        'statusCode: ${statusCode ?? 'none'}, '
        'cause: ${causeType?.toString() ?? 'none'}'
        '${causeMessage == null || causeMessage.isEmpty ? '' : ', message: $causeMessage'}'
        ')';
  }

  String buildCacheKey({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) {
    final token = TokenManager.instance.token;
    final scope = token.isEmpty
        ? 'guest'
        : sha256.convert(utf8.encode(token)).toString().substring(0, 16);
    final canonicalPayload = jsonEncode(
      _canonicalize(<String, Object?>{'query': queryParameters, 'data': data}),
    );
    return '$scope|${method.toUpperCase()}|$path|$canonicalPayload';
  }

  Object? _canonicalize(Object? value) {
    if (value is FormData) {
      return <String, Object?>{
        'fields': value.fields
            .map(
              (entry) => <String, Object?>{
                'key': entry.key,
                'value': entry.value,
              },
            )
            .toList(growable: false),
        'files': value.files
            .map(
              (entry) => <String, Object?>{
                'key': entry.key,
                'filename': entry.value.filename,
                'length': entry.value.length,
              },
            )
            .toList(growable: false),
      };
    }
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is Iterable) return value.map(_canonicalize).toList();
    return value;
  }

  String _normalizePath(String path) {
    if (path.startsWith('http')) return path;
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
