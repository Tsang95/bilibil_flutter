import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/models/fan_user.dart';
import 'package:b_flutter/models/paged_result.dart';

typedef FanPageLoader =
    Future<PagedResult<FanUser>> Function(int page, bool forceRefresh);

final class MyFansController extends ChangeNotifier {
  MyFansController({this.type = 0, FanPageLoader? loader})
    : _loader =
          loader ??
          ((page, forceRefresh) => type == 0
              ? UserApi.getFans(page: page, forceRefresh: forceRefresh)
              : UserApi.getFollowingUsers(
                  page: page,
                  forceRefresh: forceRefresh,
                ));

  final int type;
  final FanPageLoader _loader;
  final List<FanUser> _items = <FanUser>[];
  final Set<int> _submittingIds = <int>{};
  bool _disposed = false;
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _error;

  List<FanUser> get items => List<FanUser>.unmodifiable(_items);
  bool get initialLoading => _initialLoading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  bool isSubmitting(FanUser user) => _submittingIds.contains(user.relationId);

  Future<void> loadInitial() => _replace(forceRefresh: false);
  Future<void> refresh() => _replace(forceRefresh: true);

  Future<void> _replace({required bool forceRefresh}) async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    _notify();
    try {
      final result = await _loader(1, forceRefresh);
      final ids = <int>{};
      _items
        ..clear()
        ..addAll(
          result.items.where(
            (item) => item.relationId == 0 || ids.add(item.relationId),
          ),
        );
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
      final requestPage = _page + 1;
      final result = await _loader(requestPage, false);
      final ids = _items.map((item) => item.relationId).toSet();
      final added = result.items.where(
        (item) => item.relationId == 0 || ids.add(item.relationId),
      );
      _items.addAll(added);
      _page = result.page > _page ? result.page : requestPage;
      _hasMore = result.hasMore && result.items.isNotEmpty;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<void> follow(FanUser user) async {
    if (user.relationId <= 0 || isSubmitting(user)) return;
    _submittingIds.add(user.relationId);
    _notify();
    try {
      // The legacy controller passes the access-list record id, rather than
      // the nested fan member id, to `focusOns`.
      await UserApi.toggleFollow(userId: user.relationId);
      _items.removeWhere((item) => item.relationId == user.relationId);
    } finally {
      _submittingIds.remove(user.relationId);
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
