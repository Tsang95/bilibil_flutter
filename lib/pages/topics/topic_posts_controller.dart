import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/topic_api.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';

typedef TopicPostsLoader = Future<PagedResult<PostSummary>> Function({
  required int topicId,
  required int page,
  required bool forceRefresh,
});

final class TopicPostsController extends ChangeNotifier {
  TopicPostsController(this.topicId, {TopicPostsLoader? loader})
      : _loader = loader ?? _loadTopicPosts;

  final int topicId;
  final TopicPostsLoader _loader;
  final List<PostSummary> _items = <PostSummary>[];
  bool _disposed = false;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _error;

  List<PostSummary> get items => List<PostSummary>.unmodifiable(_items);
  bool get initialLoading => _initialLoading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;

  Future<void> loadInitial() => _replace(forceRefresh: false);

  Future<void> refresh() => _replace(forceRefresh: true);

  Future<void> _replace({required bool forceRefresh}) async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _notify();
    try {
      final result = await _loader(
        topicId: topicId,
        page: 1,
        forceRefresh: forceRefresh,
      );
      _items
        ..clear()
        ..addAll(result.items);
      _page = result.page == 0 ? 1 : result.page;
      _hasMore = result.hasMore;
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
    _notify();
    try {
      final result = await _loader(
        topicId: topicId,
        page: _page + 1,
        forceRefresh: false,
      );
      final ids = _items.map((item) => item.id).toSet();
      _items.addAll(
        result.items.where((item) => item.id == 0 || ids.add(item.id)),
      );
      _page = result.page == 0 ? _page + 1 : result.page;
      _hasMore = result.hasMore;
    } catch (_) {
      // Keep infinite-scroll failures unobtrusive; pull-to-refresh exposes a
      // visible retry path, matching the rest of the paged content flows.
    } finally {
      _loadingMore = false;
      _notify();
    }
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

Future<PagedResult<PostSummary>> _loadTopicPosts({
  required int topicId,
  required int page,
  required bool forceRefresh,
}) =>
    TopicApi.getTopicPosts(
      topicId: topicId,
      page: page,
      forceRefresh: forceRefresh,
    );
