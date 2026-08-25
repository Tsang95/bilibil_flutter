import 'dart:async';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/active_api.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/toast.dart';

final class CreateActiveController extends ChangeNotifier {
  static const int _chunkSize = 2 * 1024 * 1024;

  final HtmlEditorController contentController = HtmlEditorController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _coverUrls = <String>[];
  final Map<String, String> _localPaths = <String, String>{};
  final Map<String, String> _editorImageUrls = <String, String>{};
  CancelToken? _videoCancelToken;
  bool _disposed = false;
  bool _posting = false;
  bool _uploadingImage = false;
  bool _uploadingVideo = false;
  double _videoProgress = 0;
  String _videoUrl = '';

  List<String> get coverUrls => List<String>.unmodifiable(_coverUrls);
  int get coverItemCount => _coverUrls.length < 30 ? _coverUrls.length + 1 : 30;
  bool get posting => _posting;
  bool get uploadingImage => _uploadingImage;
  bool get uploadingVideo => _uploadingVideo;
  double get videoProgress => _videoProgress;
  String get videoUrl => _videoUrl;

  String localPath(String url) => _localPaths[url] ?? '';

  Future<void> clearEditorFocus() async {
    contentController.clearFocus();
    final editor = contentController.editorController;
    if (editor == null) return;
    try {
      await editor.evaluateJavascript(
        source: r'''
          $('#summernote-2').summernote('blur');
          if (document.activeElement) {
            document.activeElement.blur();
          }
        ''',
      );
      await editor.clearFocus();
    } catch (_) {
      // The platform view may already be detached while the keyboard closes.
    }
  }

  Future<XFile?> _pickImage(BuildContext context, String title) async {
    final result = await showModalActionSheet<String>(
      context: context,
      title: title,
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (result != 'photo' && result != 'camera') return null;
    return _picker.pickImage(
      source: result == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
  }

  Future<void> addCover(BuildContext context) async {
    if (_uploadingImage || _coverUrls.length >= 30) return;
    final file = await _pickImage(context, '选择封面图');
    if (file == null) return;
    _uploadingImage = true;
    _notify();
    try {
      final result = await SubmissionFeedback.run(
        action: () =>
            ActiveApi.uploadImage(filePath: file.path, fileName: file.name),
        loadingMessage: '正在上传图片...',
        successMessage: '上传成功',
        fallbackErrorMessage: '图片上传失败，请稍后重试',
      );
      if (result.url.isEmpty) throw const FormatException('Empty image url');
      _coverUrls.add(result.url);
      _localPaths[result.url] = file.path;
    } catch (_) {
      // SubmissionFeedback reports the failure.
    } finally {
      _uploadingImage = false;
      _notify();
    }
  }

  void removeCoverAt(int index) {
    if (index < 0 || index >= _coverUrls.length) return;
    final url = _coverUrls.removeAt(index);
    _localPaths.remove(url);
    _notify();
  }

  Future<void> addEditorImage(BuildContext context) async {
    if (_uploadingImage) return;
    final file = await _pickImage(context, '选择图片');
    if (file == null) return;
    _uploadingImage = true;
    _notify();
    try {
      final result = await SubmissionFeedback.run(
        action: () =>
            ActiveApi.uploadImage(filePath: file.path, fileName: file.name),
        loadingMessage: '正在上传图片...',
        successMessage: '上传成功',
        fallbackErrorMessage: '图片上传失败，请稍后重试',
      );
      final displayUrl = LegacyNetworkImage.resolveUrl(result.url);
      if (displayUrl.isEmpty) throw const FormatException('Empty image url');
      _editorImageUrls[displayUrl] = result.url;
      contentController.insertNetworkImage(displayUrl, filename: file.name);
    } catch (_) {
      // SubmissionFeedback reports the failure.
    } finally {
      _uploadingImage = false;
      _notify();
    }
  }

  Future<void> selectAndUploadVideo() async {
    if (_uploadingVideo) return;
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadVideo(file);
  }

  Future<void> _uploadVideo(XFile selected) async {
    _videoCancelToken?.cancel();
    final cancelToken = CancelToken();
    _videoCancelToken = cancelToken;
    _uploadingVideo = true;
    _videoProgress = 0.01;
    _videoUrl = '';
    _notify();

    RandomAccessFile? reader;
    try {
      final file = File(selected.path);
      final length = await file.length();
      final totalChunks = (length / _chunkSize).ceil();
      reader = await file.open();
      for (var index = 0; index < totalChunks; index++) {
        if (cancelToken.isCancelled) return;
        final start = index * _chunkSize;
        final byteCount = mathMin(_chunkSize, length - start);
        await reader.setPosition(start);
        final bytes = await reader.read(byteCount);
        final result = await ActiveApi.uploadVideoChunk(
          bytes: bytes,
          fileName: selected.name,
          chunkNumber: index + 1,
          totalChunks: totalChunks,
          cancelToken: cancelToken,
        );
        if (result.status == 1 && result.url.isNotEmpty) {
          _videoUrl = result.url;
        }
        _videoProgress = (index + 1) / totalChunks;
        _notify();
      }
      if (_videoUrl.isEmpty) {
        throw const ApiException(
          type: ApiExceptionType.business,
          message: '服务器未返回视频地址，请重新上传',
        );
      }
      if (!cancelToken.isCancelled) {
        showToast('上传成功', type: ToastType.success);
      }
    } on ApiException catch (error) {
      if (error.type != ApiExceptionType.cancelled) {
        showToast(error.message, type: ToastType.error);
      }
    } catch (_) {
      showToast('视频上传失败，请稍后重试', type: ToastType.error);
    } finally {
      await reader?.close();
      if (identical(_videoCancelToken, cancelToken)) {
        _uploadingVideo = false;
        if (cancelToken.isCancelled) _videoProgress = 0;
        _notify();
      }
    }
  }

  void cancelVideoUpload() {
    _videoCancelToken?.cancel('user cancelled');
    _videoCancelToken = null;
    _uploadingVideo = false;
    _videoProgress = 0;
    _videoUrl = '';
    showToast('已取消上传', type: ToastType.info);
    _notify();
  }

  Future<bool> publish() async {
    if (_posting) return false;
    if (_coverUrls.isEmpty) {
      showToast('请上传封面图', type: ToastType.error);
      return false;
    }
    _posting = true;
    _notify();
    try {
      var description = await contentController.getText();
      _editorImageUrls.forEach((displayUrl, backendUrl) {
        description = description.replaceAll(displayUrl, backendUrl);
      });
      await SubmissionFeedback.run<void>(
        action: () => ActiveApi.releaseDynamic(
          coverImages: _coverUrls,
          description: description,
          videoUrl: _videoUrl,
        ),
        loadingMessage: '正在发布...',
        successMessage: '发布成功，等待审核',
        fallbackErrorMessage: '发布失败，请稍后重试',
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _posting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _videoCancelToken?.cancel('page disposed');
    _disposed = true;
    super.dispose();
  }
}

int mathMin(int left, int right) => left < right ? left : right;
