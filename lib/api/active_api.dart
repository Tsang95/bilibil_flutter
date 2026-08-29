import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:b_flutter/models/invite_summary.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/upload_file_result.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class ActiveApi {
  static Future<PagedResult<PostSummary>> getDynamics({
    required int page,
    required int type,
    bool forceRefresh = false,
  }) {
    return ApiClient().get<PagedResult<PostSummary>>(
      'api/dynamicLists',
      data: <String, Object?>{
        'page': page,
        'describe': '',
        'size': 10,
        'type': type,
      },
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid dynamics page');
        return PagedResult<PostSummary>.fromJson(
          Map<String, dynamic>.from(data),
          PostSummary.fromJson,
        );
      },
      cachePolicy: forceRefresh
          ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
          : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
      cacheTags: <String>{'dynamics_$type'},
    );
  }

  static Future<UploadFileResult> uploadImage({
    required String filePath,
    required String fileName,
  }) async {
    final form = FormData.fromMap(<String, Object?>{
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return ApiClient().post<UploadFileResult>(
      'api/uploads',
      data: form,
      parser: _parseUpload,
      deduplicate: false,
    );
  }

  static Future<UploadFileResult> uploadVideoChunk({
    required List<int> bytes,
    required String fileName,
    required int chunkNumber,
    required int totalChunks,
    CancelToken? cancelToken,
  }) =>
      retryTransientUpload<UploadFileResult>(
        action: () => ApiClient().post<UploadFileResult>(
          'api/bigFileUploads',
          data: FormData.fromMap(<String, Object?>{
            'chunk': MultipartFile.fromBytes(bytes, filename: fileName),
            'filename': fileName,
            'chunked': true,
            'chunkNumber': chunkNumber,
            'totalChunks': totalChunks,
          }),
          parser: _parseUpload,
          deduplicate: false,
          cancelToken: cancelToken,
        ),
      );

  static Future<T> retryTransientUpload<T>({
    required Future<T> Function() action,
    List<Duration> retryDelays = const <Duration>[
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  }) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await action();
      } on ApiException catch (error) {
        final canRetry = error.type == ApiExceptionType.timeout ||
            error.type == ApiExceptionType.connection ||
            error.type == ApiExceptionType.unknown ||
            error.statusCode == 500 ||
            error.statusCode == 503;
        if (!canRetry || attempt >= retryDelays.length) rethrow;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }
  }

  static Future<void> releaseDynamic({
    required List<String> coverImages,
    required String description,
    required String videoUrl,
  }) {
    return ApiClient().post<void>(
      'api/releaseDynamics',
      data: <String, Object?>{
        'describe': description,
        'cover_images': jsonEncode(coverImages),
        'video_url': videoUrl,
      },
      parser: (_) {},
      deduplicate: true,
      invalidateCacheTags: const <String>{'dynamics_0', 'dynamics_1'},
    );
  }

  static Future<InviteSummary> getInviteSummary() {
    return ApiClient().get<InviteSummary>(
      'api/shareUsers',
      parser: (data) {
        if (data is! Map) throw const FormatException('Invalid invite data');
        return InviteSummary.fromJson(Map<String, dynamic>.from(data));
      },
      cachePolicy: const CachePolicy.networkFirst(ttl: Duration(minutes: 1)),
      cacheTags: const <String>{'invite_summary'},
      lock: true,
      lockText: '加载中...',
    );
  }

  static UploadFileResult _parseUpload(Object? data) {
    if (data is! Map) throw const FormatException('Invalid upload result');
    return UploadFileResult.fromJson(Map<String, dynamic>.from(data));
  }
}
