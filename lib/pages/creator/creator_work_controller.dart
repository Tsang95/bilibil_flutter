import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/active_api.dart';
import 'package:b_flutter/api/creator_api.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/creator_publish_models.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/toast.dart';

enum CreatorImageTarget { cover, horizontalCover, comic, description, content }

final class CreatorWorkController extends ChangeNotifier {
  CreatorWorkController({this.initialTopicId});

  static const int _chunkSize = 2 * 1024 * 1024;

  final int? initialTopicId;
  final TextEditingController titleController = TextEditingController();
  final HtmlEditorController descriptionController = HtmlEditorController();
  final HtmlEditorController contentController = HtmlEditorController();
  final ImagePicker _picker = ImagePicker();

  CreatorPublishOptions? options;
  List<CreatorPublishOption> topics = const <CreatorPublishOption>[];
  List<CreatorPublishOption> collections = const <CreatorPublishOption>[];
  CreatorPlate? selectedPlate;
  CreatorPublishOption? selectedCategory;
  CreatorPublishOption? selectedContentType;
  CreatorPublishOption? selectedTopic;
  CreatorPublishOption? selectedCollectionType;
  CreatorPublishOption? selectedCollection;
  CreatorPriceOption? selectedPrice;
  int vipWatch = 0;
  int vipComment = 0;
  bool loading = true;
  bool publishing = false;
  bool uploadingImage = false;
  bool uploadingVideo = false;
  Object? error;
  double videoProgress = 0;
  String videoUrl = '';

  final List<String> coverUrls = <String>[];
  final List<String> horizontalCoverUrls = <String>[];
  final List<String> comicUrls = <String>[];
  final Map<String, String> localPaths = <String, String>{};
  final Map<String, String> _descriptionImageUrls = <String, String>{};
  final Map<String, String> _contentImageUrls = <String, String>{};
  CancelToken? _videoCancelToken;
  bool _disposed = false;

  int get contentType => selectedContentType?.id ?? 0;
  int get collectionType => selectedCollectionType?.id ?? 0;
  bool get showHorizontalCover => contentType == 5 && collectionType == 1;
  bool get showComicImages =>
      (contentType == 2 || contentType == 5) && collectionType != 1;
  bool get showMediaUpload =>
      contentType != 2 && contentType != 5 && collectionType != 1;
  bool get showContentEditor => contentType == 3;
  bool get showPaidOptions => options?.formIsShown == true;
  bool get showCollection => collections.isNotEmpty && collectionType == 2;
  String localPath(String url) => localPaths[url] ?? '';

  Future<void> load({bool forceRefresh = false}) async {
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        CreatorApi.getPublishOptions(forceRefresh: forceRefresh),
        CreatorApi.getTopics(forceRefresh: forceRefresh),
        CreatorApi.getCollections(forceRefresh: forceRefresh),
      ]);
      options = results[0] as CreatorPublishOptions;
      topics = results[1] as List<CreatorPublishOption>;
      collections = results[2] as List<CreatorPublishOption>;
      final topicId = initialTopicId;
      if (topicId != null) {
        for (final topic in topics) {
          if (topic.id == topicId) {
            selectedTopic = topic;
            break;
          }
        }
      }
      if (!showPaidOptions) {
        selectedPrice = null;
        vipWatch = 1;
      }
    } catch (loadError) {
      error = loadError;
    } finally {
      loading = false;
      _notify();
    }
  }

  void selectPlate(CreatorPlate value) {
    selectedPlate = value;
    selectedCategory = null;
    _notify();
  }

  void selectCategory(CreatorPublishOption value) {
    selectedCategory = value;
    _notify();
  }

  void selectContentType(CreatorPublishOption value) {
    selectedContentType = value;
    _notify();
  }

  void selectTopic(CreatorPublishOption value) {
    selectedTopic = value;
    _notify();
  }

  void selectCollectionType(CreatorPublishOption value) {
    selectedCollectionType = value;
    selectedCollection = null;
    _notify();
  }

  void selectCollection(CreatorPublishOption value) {
    selectedCollection = value;
    _notify();
  }

  void selectPrice(CreatorPriceOption value) {
    selectedPrice = value;
    _notify();
  }

  void setVipWatch(int value) {
    vipWatch = value;
    _notify();
  }

  void setVipComment(int value) {
    vipComment = value;
    _notify();
  }

  Future<XFile?> _pickImage(BuildContext context, String title) async {
    final choice = await showModalActionSheet<String>(
      context: context,
      title: title,
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (choice != 'photo' && choice != 'camera') return null;
    return _picker.pickImage(
      source: choice == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
  }

  Future<void> addImage(BuildContext context, CreatorImageTarget target) async {
    if (uploadingImage) return;
    final file = await _pickImage(context, '选择封面图');
    if (file == null) return;
    uploadingImage = true;
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
      localPaths[result.url] = file.path;
      switch (target) {
        case CreatorImageTarget.cover:
          if (coverUrls.length < 3) coverUrls.add(result.url);
        case CreatorImageTarget.horizontalCover:
          if (horizontalCoverUrls.isEmpty) horizontalCoverUrls.add(result.url);
        case CreatorImageTarget.comic:
          if (comicUrls.length < 30) comicUrls.add(result.url);
        case CreatorImageTarget.description:
          final displayUrl = LegacyNetworkImage.resolveUrl(result.url);
          _descriptionImageUrls[displayUrl] = result.url;
          descriptionController.insertNetworkImage(
            displayUrl,
            filename: file.name,
          );
        case CreatorImageTarget.content:
          final displayUrl = LegacyNetworkImage.resolveUrl(result.url);
          _contentImageUrls[displayUrl] = result.url;
          contentController.insertNetworkImage(displayUrl, filename: file.name);
      }
    } catch (_) {
      // SubmissionFeedback reports the failure.
    } finally {
      uploadingImage = false;
      _notify();
    }
  }

  void removeImage(CreatorImageTarget target, int index) {
    final list = switch (target) {
      CreatorImageTarget.cover => coverUrls,
      CreatorImageTarget.horizontalCover => horizontalCoverUrls,
      CreatorImageTarget.comic => comicUrls,
      _ => null,
    };
    if (list == null || index < 0 || index >= list.length) return;
    final removed = list.removeAt(index);
    localPaths.remove(removed);
    _notify();
  }

  Future<void> selectAndUploadMedia() async {
    if (uploadingVideo) return;
    final file = contentType == 4
        ? await _picker.pickMedia()
        : await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadMedia(file);
  }

  Future<void> _uploadMedia(XFile selected) async {
    _videoCancelToken?.cancel();
    final cancelToken = CancelToken();
    _videoCancelToken = cancelToken;
    uploadingVideo = true;
    videoProgress = .01;
    videoUrl = '';
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
        final remaining = length - start;
        final bytesToRead = remaining < _chunkSize ? remaining : _chunkSize;
        await reader.setPosition(start);
        final bytes = await reader.read(bytesToRead);
        final result = await ActiveApi.uploadVideoChunk(
          bytes: bytes,
          fileName: selected.name,
          chunkNumber: index + 1,
          totalChunks: totalChunks,
          cancelToken: cancelToken,
        );
        if (result.status == 1 && result.url.isNotEmpty) videoUrl = result.url;
        videoProgress = (index + 1) / totalChunks;
        _notify();
      }
      if (videoUrl.isEmpty) {
        throw const ApiException(
          type: ApiExceptionType.business,
          message: '服务器未返回视频地址，请重新上传',
        );
      }
      if (!cancelToken.isCancelled) {
        showToast('上传成功', type: ToastType.success);
      }
    } on ApiException catch (uploadError) {
      if (uploadError.type != ApiExceptionType.cancelled) {
        showToast(uploadError.message, type: ToastType.error);
      }
    } catch (_) {
      showToast('视频上传失败，请稍后重试', type: ToastType.error);
    } finally {
      await reader?.close();
      if (identical(_videoCancelToken, cancelToken)) {
        uploadingVideo = false;
        if (cancelToken.isCancelled) videoProgress = 0;
        _notify();
      }
    }
  }

  void cancelMediaUpload() {
    _videoCancelToken?.cancel('user cancelled');
    _videoCancelToken = null;
    uploadingVideo = false;
    videoProgress = 0;
    videoUrl = '';
    showToast('已取消上传', type: ToastType.info);
    _notify();
  }

  Future<bool> publish() async {
    if (publishing) return false;
    if (selectedPlate == null) return _validation('请选择板块');
    if (selectedCategory == null) return _validation('请选择分类');
    if (selectedContentType == null) return _validation('请选择帖子类型');
    if (titleController.text.trim().isEmpty) return _validation('请输入标题');
    if (coverUrls.isEmpty) return _validation('请上传封面图');
    if (horizontalCoverUrls.isEmpty && contentType == 6) {
      return _validation('请上传横封面图');
    }
    if (contentType == 1 && collectionType != 1 && videoUrl.isEmpty) {
      return _validation('请上传视频');
    }
    publishing = true;
    _notify();
    try {
      var description = await descriptionController.getText();
      _descriptionImageUrls.forEach((display, backend) {
        description = description.replaceAll(display, backend);
      });
      Object? content;
      if (contentType == 2 || contentType == 5) {
        content = jsonEncode(comicUrls);
      } else if (contentType == 3) {
        var html = await contentController.getText();
        _contentImageUrls.forEach((display, backend) {
          html = html.replaceAll(display, backend);
        });
        content = html;
      }
      final payload = <String, Object?>{
        'plate_one_id': selectedPlate!.id,
        'plate_two_id': selectedCategory!.id,
        'type': contentType,
        'collection_id': jsonEncode(
          selectedCollection == null ? <int>[] : <int>[selectedCollection!.id],
        ),
        'title': titleController.text.trim(),
        'cover_images': jsonEncode(coverUrls),
        'horizontal_images': jsonEncode(horizontalCoverUrls),
        'describe': description,
      };
      if (selectedTopic != null) payload['topic_id'] = selectedTopic!.id;
      if (selectedCollectionType != null) {
        payload['collection_type'] = selectedCollectionType!.id;
      }
      if (showPaidOptions) {
        if (selectedPrice != null) payload['price'] = selectedPrice!.value;
        payload['is_vip_watch'] = vipWatch;
        payload['is_vip_comment'] = vipComment;
      } else {
        payload['price'] = 0;
        payload['is_vip_watch'] = 1;
      }
      if (content != null) payload['content'] = content;
      if (contentType != 2 && contentType != 5) {
        payload['video_url'] = contentType == 1 ? videoUrl : '';
      }
      await SubmissionFeedback.run<void>(
        action: () => CreatorApi.publishWork(data: payload),
        loadingMessage: '发布中...',
        successMessage: '发布成功',
        fallbackErrorMessage: '发布失败，请稍后重试',
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      publishing = false;
      _notify();
    }
  }

  bool _validation(String message) {
    showToast(message, type: ToastType.error);
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _videoCancelToken?.cancel('page disposed');
    titleController.dispose();
    _disposed = true;
    super.dispose();
  }
}
