import 'package:flutter/foundation.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';

typedef HomePageLoader = Future<PagedResult<PostSummary>> Function(
    int page, bool forceRefresh);

final class HomeFeedController extends ChangeNotifier {
  HomeFeedController(this._loader);

  final HomePageLoader _loader;
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
  bool get refreshing => _refreshing;
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
      final result = await _loader(1, forceRefresh);
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
      final result = await _loader(_page + 1, false);
      final existingIds = _items.map((item) => item.id).toSet();
      _items.addAll(
        result.items.where((item) => item.id == 0 || existingIds.add(item.id)),
      );
      _page = result.page == 0 ? _page + 1 : result.page;
      _hasMore = result.hasMore;
    } catch (_) {
      // Infinite-scroll errors stay unobtrusive. Pull-to-refresh and explicit
      // retry expose full feedback to the user.
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
