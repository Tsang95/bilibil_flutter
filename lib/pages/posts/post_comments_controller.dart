import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_comment.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

typedef PostCommentsLoader = Future<PagedResult<PostComment>> Function(
    int page, bool forceRefresh);

final class PostCommentsController extends ChangeNotifier {
  PostCommentsController(this.postId, {PostCommentsLoader? loader})
      : _loader = loader ??
            ((page, forceRefresh) => PostApi.getComments(
                  postId: postId,
                  page: page,
                  forceRefresh: forceRefresh,
                ));

  final int postId;
  final PostCommentsLoader _loader;
  final List<PostComment> _items = <PostComment>[];
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _submitting = false;
  bool _hasMore = true;
  bool _disposed = false;
  int _page = 0;
  Object? _error;
  Object? _loadMoreError;

  List<PostComment> get items => List<PostComment>.unmodifiable(_items);
  bool get loading => _initialLoading || _refreshing;
  bool get loadingMore => _loadingMore;
  bool get submitting => _submitting;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  Object? get loadMoreError => _loadMoreError;

  Future<void> load({bool forceRefresh = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _loadMoreError = null;
    _notify();
    try {
      final result = await _loader(1, forceRefresh);
      _items
        ..clear()
        ..addAll(_unique(result.items));
      _page = result.page == 0 ? 1 : result.page;
      _hasMore = result.hasMore && result.items.isNotEmpty;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _initialLoading = false;
      _refreshing = false;
      _notify();
    }
  }

  Future<void> loadMore() async {
    if (_initialLoading || _refreshing || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    _loadMoreError = null;
    _notify();
    try {
      final requestedPage = _page + 1;
      final result = await _loader(requestedPage, false);
      final existingIds = _items.map((item) => item.id).toSet();
      final additions = result.items
          .where((item) => item.id == 0 || existingIds.add(item.id))
          .toList(growable: false);
      _items.addAll(additions);
      _page = result.page > _page ? result.page : requestedPage;
      _hasMore =
          result.hasMore && result.items.isNotEmpty && additions.isNotEmpty;
    } catch (error) {
      _loadMoreError = error;
      rethrow;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<bool> submit({required String content, PostComment? replyTo}) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      showToast('请输入评论内容', type: ToastType.warning);
      return false;
    }
    if (!TokenManager.instance.hasToken) {
      showToast('请先登录后再评论', type: ToastType.warning);
      return false;
    }
    if (_submitting) return false;
    _submitting = true;
    _notify();
    try {
      await SubmissionFeedback.run<void>(
        action: () => replyTo == null
            ? PostApi.sendComment(postId: postId, content: normalized)
            : PostApi.sendReply(
                postId: postId,
                commentId: replyTo.id,
                content: normalized,
              ),
        loadingMessage: replyTo == null ? '评论提交中...' : '回复提交中...',
        successMessage: replyTo == null ? '评论成功，请等待审核' : '回复成功，请等待审核',
      );
      return true;
    } finally {
      _submitting = false;
      _notify();
    }
  }

  List<PostComment> _unique(List<PostComment> values) {
    final ids = <int>{};
    return values
        .where((item) => item.id == 0 || ids.add(item.id))
        .toList(growable: false);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
