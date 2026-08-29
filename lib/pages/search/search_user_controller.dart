import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/search_api.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/search_user.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

typedef SearchUserPageLoader = Future<PagedResult<SearchUser>> Function(
    int page, bool forceRefresh);

final class SearchUserController extends ChangeNotifier {
  SearchUserController(this.keyword, {SearchUserPageLoader? loader})
      : _loader = loader ??
            ((page, forceRefresh) => SearchApi.searchUsers(
                  keyword: keyword,
                  page: page,
                  forceRefresh: forceRefresh,
                ));

  final String keyword;
  final SearchUserPageLoader _loader;
  final List<SearchUser> _items = <SearchUser>[];
  final Set<int> _submittingUserIds = <int>{};
  bool _initialLoading = true;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _disposed = false;
  int _page = 0;
  Object? _error;
  Object? _loadMoreError;

  List<SearchUser> get items => List<SearchUser>.unmodifiable(_items);
  bool get loading => _initialLoading || _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  Object? get loadMoreError => _loadMoreError;
  bool isSubmitting(int userId) => _submittingUserIds.contains(userId);

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
        ..addAll(result.items);
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
      final newItems = result.items
          .where((item) => item.id == 0 || existingIds.add(item.id))
          .toList(growable: false);
      _items.addAll(newItems);
      _page = result.page > _page ? result.page : requestedPage;
      _hasMore =
          result.hasMore && result.items.isNotEmpty && newItems.isNotEmpty;
    } catch (error) {
      _loadMoreError = error;
      rethrow;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<void> toggleFollow(SearchUser user) async {
    if (_submittingUserIds.contains(user.id)) return;
    if (!TokenManager.instance.hasToken) {
      showToast('请先登录后再关注', type: ToastType.warning);
      return;
    }

    _submittingUserIds.add(user.id);
    _notify();
    try {
      await SubmissionFeedback.run<void>(
        action: () => SearchApi.toggleFollow(userId: user.id),
        loadingMessage: user.isFollowing ? '取消关注中...' : '关注中...',
        successMessage: user.isFollowing ? '已取消关注' : '关注成功',
      );
      final index = _items.indexWhere((item) => item.id == user.id);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(isFollowing: !user.isFollowing);
      }
    } finally {
      _submittingUserIds.remove(user.id);
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
