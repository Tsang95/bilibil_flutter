import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

typedef PostDetailLoader = Future<PostDetail> Function(
    int postId, bool forceRefresh);
typedef PostActionRequest = Future<void> Function();

final class PostDetailController extends ChangeNotifier {
  PostDetailController(this.postId, {PostDetailLoader? loader})
      : _loader = loader ??
            ((id, forceRefresh) =>
                PostApi.getDetail(postId: id, forceRefresh: forceRefresh));

  final int postId;
  final PostDetailLoader _loader;
  final Set<String> _submitting = <String>{};
  PostDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _recommendationsLoading = false;
  bool _detailAdvertisementsLoading = false;
  bool _episodesLoading = false;
  bool _disposed = false;
  List<PostSummary> _recommendations = const <PostSummary>[];
  List<BannerItem> _detailAdvertisements = const <BannerItem>[];
  List<PostSummary> _episodes = const <PostSummary>[];
  int _episodePage = 1;
  int _episodeTotal = 0;

  PostDetail? get detail => _detail;
  Object? get error => _error;
  bool get loading => _loading;
  bool get recommendationsLoading => _recommendationsLoading;
  bool get detailAdvertisementsLoading => _detailAdvertisementsLoading;
  bool get episodesLoading => _episodesLoading;
  List<PostSummary> get recommendations => _recommendations;
  List<BannerItem> get detailAdvertisements => _detailAdvertisements;
  List<PostSummary> get episodes => _episodes;
  int get episodePage => _episodePage;
  int get episodeTotal => _episodeTotal;
  bool get showEpisodeSection => _episodesLoading || _episodes.isNotEmpty;
  bool isSubmitting(String action) => _submitting.contains(action);

  Future<void> load({bool forceRefresh = false}) async {
    if (_loading && _detail != null) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final loaded = await _loader(postId, forceRefresh);
      _detail = loaded;
      unawaited(_loadRecommendations(loaded.primaryCategoryId));
      unawaited(_loadDetailAdvertisements(forceRefresh: forceRefresh));
      if (loaded.isCollection) unawaited(_loadInitialEpisodes());
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> toggleLike() async {
    final value = _detail;
    if (value == null || !_requireLogin()) return;
    final wasLiked = value.isLiked;
    await _submit(
      key: 'like',
      request: () => PostApi.toggleLike(postId: value.id),
      loadingMessage: wasLiked ? '取消点赞中...' : '点赞中...',
      successMessage: wasLiked ? '已取消点赞' : '点赞成功',
      onSuccess: () {
        _detail = value.copyWith(
          isLiked: !wasLiked,
          likeCount: _changedCount(value.likeCount, increase: !wasLiked),
        );
      },
    );
  }

  Future<void> toggleCollect() async {
    final value = _detail;
    if (value == null || !_requireLogin()) return;
    final wasCollected = value.isCollected;
    await _submit(
      key: 'collect',
      request: () => PostApi.toggleCollect(postId: value.id),
      loadingMessage: wasCollected ? '取消收藏中...' : '收藏中...',
      successMessage: wasCollected ? '已取消收藏' : '收藏成功',
      onSuccess: () {
        _detail = value.copyWith(
          isCollected: !wasCollected,
          collectCount: _changedCount(
            value.collectCount,
            increase: !wasCollected,
          ),
        );
      },
    );
  }

  Future<void> tipCoin(int count) async {
    final value = _detail;
    if (value == null || !_requireLogin() || count < 1) return;
    await _submit(
      key: 'coin',
      request: () => PostApi.tipCoin(postId: value.id, count: count),
      loadingMessage: '投币中...',
      successMessage: '投币成功',
      onSuccess: () {
        _detail = value.copyWith(
          hasTippedCoin: true,
          coinCount: value.coinCount + count,
        );
      },
    );
  }

  Future<void> highlyRecommend() async {
    final value = _detail;
    if (value == null || !_requireLogin()) return;
    await _submit(
      key: 'recommend',
      request: () => PostApi.highlyRecommend(postId: value.id),
      loadingMessage: '推荐中...',
      successMessage: '推荐成功',
      onSuccess: () {},
    );
  }

  Future<void> reward(PostRewardProduct product) async {
    final value = _detail;
    if (value == null || !_requireLogin()) return;
    await _submit(
      key: 'reward',
      request: () => PostApi.reward(postId: value.id, productId: product.id),
      loadingMessage: '打赏中...',
      successMessage: '打赏成功',
      onSuccess: () {},
    );
  }

  Future<void> sendFeedback({
    required PostFeedbackReason reason,
    required String content,
  }) async {
    final value = _detail;
    if (value == null || !_requireLogin()) return;
    await _submit(
      key: 'feedback',
      request: () => PostApi.sendFeedback(
        postId: value.id,
        reasonId: reason.id,
        content: content,
      ),
      loadingMessage: '正在提交反馈...',
      successMessage: '反馈提交成功',
      onSuccess: () {},
    );
  }

  // 产品决定本期不开放帖子视频下载。保留旧流程供后续版本恢复，
  // 当前不向页面暴露购买下载权限或获取下载地址的业务入口。
  /*
  Future<void> buyDownload() async {
    final value = _detail;
    if (value == null || !value.canDownload || !_requireLogin()) return;
    await _submit(
      key: 'buy_download',
      request: () => PostApi.buyDownload(videoId: value.videoId),
      loadingMessage: '正在购买下载权限...',
      successMessage: '下载权限购买成功',
      onSuccess: () {
        _detail = value.copyWith(hasDownloadAccess: true);
      },
    );
  }

  Future<String?> getDownloadUrl() async {
    final value = _detail;
    if (value == null || !value.canDownload || !_requireLogin()) return null;
    if (!_submitting.add('download')) return null;
    _notify();
    try {
      return await SubmissionFeedback.run<String>(
        action: () => PostApi.getDownloadUrl(videoId: value.videoId),
        loadingMessage: '正在获取下载地址...',
        successMessage: '下载地址获取成功',
        fallbackErrorMessage: '下载地址获取失败',
      );
    } finally {
      _submitting.remove('download');
      _notify();
    }
  }
  */

  Future<List<PostRewardProduct>> loadRewardProducts() {
    if (!_requireLogin()) {
      return Future<List<PostRewardProduct>>.value(const []);
    }
    return PostApi.getRewardProducts();
  }

  Future<List<PostFeedbackReason>> loadFeedbackReasons() {
    if (!_requireLogin()) {
      return Future<List<PostFeedbackReason>>.value(const []);
    }
    return PostApi.getFeedbackReasons();
  }

  Future<void> refreshRecommendations() async {
    final value = _detail;
    if (value == null || _recommendationsLoading) return;
    _recommendationsLoading = true;
    _notify();
    try {
      final loaded = await SubmissionFeedback.run<List<PostSummary>>(
        action: () => PostApi.getRecommendations(
          categoryId: value.primaryCategoryId,
          forceRefresh: true,
        ),
        successMessage: '推荐内容已更新',
        loadingMessage: '正在换一批...',
        fallbackErrorMessage: '推荐内容更新失败',
      );
      _recommendations = loaded
          .where((item) => item.id != value.id)
          .take(10)
          .toList(growable: false);
    } finally {
      _recommendationsLoading = false;
      _notify();
    }
  }

  Future<void> loadEpisodePage(
    int page, {
    int sort = 0,
    int size = 10,
    bool append = false,
  }) async {
    if (_episodesLoading || page < 1) return;
    _episodesLoading = true;
    _notify();
    try {
      await SubmissionFeedback.run<void>(
        action: () =>
            _loadEpisodes(page: page, sort: sort, size: size, append: append),
        successMessage: '选集已更新',
        loadingMessage: '正在加载选集...',
        fallbackErrorMessage: '选集加载失败',
      );
    } finally {
      _episodesLoading = false;
      _notify();
    }
  }

  Future<void> selectEpisode(PostSummary episode) async {
    final current = _detail;
    if (current == null || episode.id == current.id) return;
    await _submit(
      key: 'episode',
      request: () async {
        _detail = await PostApi.getDetail(
          postId: episode.id,
          forceRefresh: true,
        );
      },
      loadingMessage: '正在切换选集...',
      successMessage: '已切换到${episode.title.isEmpty ? '所选内容' : episode.title}',
      onSuccess: () {},
    );
  }

  Future<void> _loadRecommendations(int categoryId) async {
    if (_recommendationsLoading) return;
    _recommendationsLoading = true;
    _notify();
    try {
      final loaded = await PostApi.getRecommendations(categoryId: categoryId);
      if (_disposed) return;
      _recommendations = loaded
          .where((item) => item.id != _detail?.id)
          .take(10)
          .toList(growable: false);
    } catch (_) {
      // 推荐属于详情增强内容，首屏静默失败。
    } finally {
      _recommendationsLoading = false;
      _notify();
    }
  }

  Future<void> _loadDetailAdvertisements({required bool forceRefresh}) async {
    if (_detailAdvertisementsLoading) return;
    _detailAdvertisementsLoading = true;
    _notify();
    try {
      final loaded = await PostApi.getDetailAdvertisements(
        forceRefresh: forceRefresh,
      );
      if (_disposed) return;
      _detailAdvertisements = loaded;
    } catch (_) {
      // 广告属于增强内容，不阻断详情主体加载。
    } finally {
      _detailAdvertisementsLoading = false;
      _notify();
    }
  }

  Future<void> _loadEpisodes({
    required int page,
    int sort = 0,
    int size = 10,
    bool append = false,
  }) async {
    final result = await PostApi.getEpisodes(
      postId: postId,
      page: page,
      size: size,
      sort: sort,
    );
    if (_disposed) return;
    _episodes =
        append ? <PostSummary>[..._episodes, ...result.items] : result.items;
    _episodePage = page;
    _episodeTotal = result.totalItems;
    _notify();
  }

  Future<void> _loadInitialEpisodes() async {
    if (_episodesLoading) return;
    _episodesLoading = true;
    _notify();
    try {
      await _loadEpisodes(page: 1, size: _detail?.type == 5 ? 16 : 10);
    } catch (_) {
      // 选集属于合集增强内容，首屏失败时隐藏空区域。
    } finally {
      _episodesLoading = false;
      _notify();
    }
  }

  Future<void> buy() async {
    final value = _detail;
    if (value == null || !value.requiresCoinUnlock || !_requireLogin()) return;
    await _submit(
      key: 'buy',
      request: () => PostApi.buy(postId: value.id),
      loadingMessage: '购买中...',
      successMessage: '购买成功',
      onSuccess: () => _detail = value.copyWith(isPurchased: true),
    );
  }

  Future<void> toggleFollow() async {
    final value = _detail;
    if (value == null || value.author.id == 0 || !_requireLogin()) return;
    final wasFollowing = value.author.isFollowing;
    await _submit(
      key: 'follow',
      request: () =>
          PostApi.toggleFollow(postId: value.id, memberId: value.author.id),
      loadingMessage: wasFollowing ? '取消关注中...' : '关注中...',
      successMessage: wasFollowing ? '已取消关注' : '关注成功',
      onSuccess: () {
        _detail = value.copyWith(
          author: value.author.copyWith(isFollowing: !wasFollowing),
        );
      },
    );
  }

  Future<void> _submit({
    required String key,
    required PostActionRequest request,
    required String loadingMessage,
    required String successMessage,
    required VoidCallback onSuccess,
  }) async {
    if (!_submitting.add(key)) return;
    _notify();
    try {
      await SubmissionFeedback.run<void>(
        action: request,
        loadingMessage: loadingMessage,
        successMessage: successMessage,
      );
      onSuccess();
    } finally {
      _submitting.remove(key);
      _notify();
    }
  }

  bool _requireLogin() {
    if (TokenManager.instance.hasToken) return true;
    showToast('请先登录后再操作', type: ToastType.warning);
    return false;
  }

  int _changedCount(int value, {required bool increase}) {
    return increase ? value + 1 : (value - 1).clamp(0, value);
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
