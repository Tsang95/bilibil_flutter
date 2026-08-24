import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/models/follow_user.dart';
import 'package:b_flutter/models/paged_result.dart';

enum FollowListSort {
  recommend('推荐排序', 0),
  frequent('最常访问', 1),
  recent('最近关注', 2);

  const FollowListSort(this.label, this.value);
  final String label;
  final int value;
}

typedef FollowUserPageLoader =
    Future<PagedResult<FollowUser>> Function(
      String keyword,
      FollowListSort sort,
      int page,
      bool forceRefresh,
    );

final class FollowListController extends ChangeNotifier {
  FollowListController({FollowUserPageLoader? loader})
    : _loader =
          loader ??
          ((keyword, sort, page, forceRefresh) => UserApi.getFollowedUsers(
            keyword: keyword,
            sort: sort.value,
            page: page,
            forceRefresh: forceRefresh,
          ));

  final FollowUserPageLoader _loader;
  final List<FollowUser> _items = <FollowUser>[];
  bool _disposed = false;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _error;
  String _keyword = '';
  FollowListSort _sort = FollowListSort.recommend;

  List<FollowUser> get items => List<FollowUser>.unmodifiable(_items);
  bool get initialLoading => _initialLoading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  String get keyword => _keyword;
  FollowListSort get sort => _sort;

  Future<void> loadInitial() => _replace(forceRefresh: false);
  Future<void> refresh() => _replace(forceRefresh: true);

  Future<void> search(String keyword) {
    _keyword = keyword.trim();
    return _replace(forceRefresh: true);
  }

  Future<void> changeSort(FollowListSort sort) {
    if (_sort == sort) return Future<void>.value();
    _sort = sort;
    return _replace(forceRefresh: true);
  }

  Future<void> _replace({required bool forceRefresh}) async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _notify();
    try {
      final result = await _loader(_keyword, _sort, 1, forceRefresh);
      _items
        ..clear()
        ..addAll(_deduplicate(result.items));
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
    _notify();
    try {
      final requestedPage = _page + 1;
      final result = await _loader(_keyword, _sort, requestedPage, false);
      final existingIds = _items.map((item) => item.id).toSet();
      final newItems = result.items
          .where((item) => item.id == 0 || existingIds.add(item.id))
          .toList(growable: false);
      _items.addAll(newItems);
      _page = result.page > _page ? result.page : requestedPage;
      _hasMore =
          result.hasMore && result.items.isNotEmpty && newItems.isNotEmpty;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  List<FollowUser> _deduplicate(List<FollowUser> users) {
    final ids = <int>{};
    return users
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
