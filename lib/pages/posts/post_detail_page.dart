import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/common_barrage.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/post_comment.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/posts/components/post_action_bar.dart';
import 'package:b_flutter/pages/posts/components/post_author_header.dart';
import 'package:b_flutter/pages/posts/components/post_comment_input.dart';
import 'package:b_flutter/pages/posts/components/post_comment_item.dart';
import 'package:b_flutter/pages/posts/components/post_coin_animator_dialog.dart';
import 'package:b_flutter/pages/posts/charge_user_page.dart';
import 'package:b_flutter/pages/posts/components/post_feedback_sheet.dart';
import 'package:b_flutter/pages/posts/components/post_common_barrage_list.dart';
import 'package:b_flutter/pages/posts/components/post_reward_sheet.dart';
import 'package:b_flutter/pages/posts/components/post_video_player.dart';
import 'package:b_flutter/pages/posts/post_comments_controller.dart';
import 'package:b_flutter/pages/posts/post_detail_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final PostDetailController _controller;
  late final PostCommentsController _commentsController;
  late final Listenable _animation;
  final ScrollController _informationScrollController = ScrollController();
  final ScrollController _commentsScrollController = ScrollController();
  final PageController _pageController = PageController();
  final TextEditingController _commentInputController = TextEditingController();
  final TextEditingController _barrageInputController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final FocusNode _barrageFocusNode = FocusNode();
  final PostVideoPlayerController _videoPlayerController =
      PostVideoPlayerController();
  PostComment? _replyTo;
  int _selectedTab = 0;
  bool _sendingBarrage = false;
  bool _registrationPrompted = false;
  List<CommonBarrage> _commonBarrages = const <CommonBarrage>[];
  bool _loadingCommonBarrages = false;

  @override
  void initState() {
    super.initState();
    _controller = PostDetailController(widget.postId);
    _commentsController = PostCommentsController(widget.postId);
    _animation = Listenable.merge(<Listenable>[
      _controller,
      _commentsController,
    ]);
    _commentsScrollController.addListener(_handleCommentsScroll);
    unawaited(_controller.load().catchError((_) {}));
    unawaited(_loadCommonBarrages());
  }

  Future<void> _loadCommonBarrages() async {
    if (_loadingCommonBarrages) return;
    setState(() => _loadingCommonBarrages = true);
    try {
      final barrages = await PostApi.getCommonBarrages();
      if (mounted) setState(() => _commonBarrages = barrages);
    } catch (_) {
      // 常用弹幕属于输入增强功能；加载失败时不影响普通弹幕发送。
    } finally {
      if (mounted) setState(() => _loadingCommonBarrages = false);
    }
  }

  Future<void> _refreshTab(int index) async {
    try {
      await SubmissionFeedback.run<void>(
        action: () => index == 0
            ? _controller.load(forceRefresh: true)
            : _commentsController.load(forceRefresh: true),
        successMessage: index == 0 ? '详情已刷新' : '评论已刷新',
        fallbackErrorMessage: index == 0 ? '详情刷新失败' : '评论刷新失败',
        lock: false,
      );
    } catch (_) {}
  }

  void _handleCommentsScroll() {
    if (_selectedTab != 1 || !_commentsScrollController.hasClients) return;
    if (_commentsScrollController.position.extentAfter < 320) {
      unawaited(_loadMoreComments());
    }
  }

  Future<void> _loadMoreComments() async {
    try {
      await _commentsController.loadMore();
    } catch (_) {
      // The comments footer exposes an explicit retry action.
    }
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    if (!_pageController.hasClients) {
      _handlePageChanged(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    if (index == 1 &&
        _commentsController.items.isEmpty &&
        _commentsController.error == null) {
      unawaited(_commentsController.load().catchError((_) {}));
    }
  }

  void _reply(PostComment comment) {
    setState(() => _replyTo = comment);
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
  }

  Future<void> _sendComment() async {
    try {
      final sent = await _commentsController.submit(
        content: _commentInputController.text,
        replyTo: _replyTo,
      );
      if (!sent || !mounted) return;
      _commentInputController.clear();
      _commentFocusNode.unfocus();
      setState(() => _replyTo = null);
    } catch (_) {
      // SubmissionFeedback has already reported the backend error.
    }
  }

  Future<void> _sendBarrage([String? selectedContent]) async {
    final content = (selectedContent ?? _barrageInputController.text).trim();
    if (content.isEmpty) {
      showToast('请输入弹幕内容', type: ToastType.warning);
      return;
    }
    if (_sendingBarrage) return;
    setState(() => _sendingBarrage = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => _videoPlayerController.sendBarrage(content),
        successMessage: '弹幕发送成功',
        loadingMessage: '正在发送弹幕...',
        fallbackErrorMessage: '弹幕发送失败，请稍后重试',
      );
      if (!mounted) return;
      _barrageInputController.clear();
      _barrageFocusNode.unfocus();
    } catch (_) {
      // SubmissionFeedback has already reported the backend error.
    } finally {
      if (mounted) setState(() => _sendingBarrage = false);
    }
  }

  Future<void> _openChargeUserPage(PostDetail detail) async {
    final authorId = detail.author.id > 0 ? detail.author.id : detail.memberId;
    if (authorId <= 0) {
      showToast('UP 主信息无效，暂时无法充电', type: ToastType.error);
      return;
    }
    final charged = await Get.to<bool>(
      () => ChargeUserPage(authorId: authorId, fallbackAuthor: detail.author),
    );
    if (charged == true && mounted) {
      if (Get.isRegistered<UserStore>()) {
        Get.find<UserStore>().restoreSessionInBackground();
      }
      await _controller.load(forceRefresh: true);
    }
  }

  void _scheduleRegistrationPrompt(PostDetail detail) {
    if (_registrationPrompted ||
        !detail.requiresRegistration ||
        TokenManager.instance.hasToken) {
      return;
    }
    _registrationPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_requestLoginForVideo());
    });
  }

  Future<void> _requestLoginForVideo() async {
    if (TokenManager.instance.hasToken) return;
    final shouldLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LegacyMessageDialog(
        title: '温馨提示',
        message: '请先注册或登录账号',
        confirmLabel: '确认',
        cancelLabel: '取消',
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    if (shouldLogin != true || !mounted) return;
    // AppPages currently registers its routes as `GetPage<dynamic>`. Supplying
    // `bool` here makes Flutter cast the generated `Route<dynamic>` to
    // `Route<bool?>` before it is pushed, which fails at runtime. Keep the
    // route result dynamic at the navigation boundary and validate it below.
    final loggedIn = await Get.toNamed(AppRoutes.login);
    if (loggedIn == true && mounted) {
      await _controller.load(forceRefresh: true);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // SubmissionFeedback has already reported the backend error.
    }
  }

  Future<void> _selectCoinCount() async {
    if (_controller.isSubmitting('coin')) return;
    final balance = Get.isRegistered<UserStore>()
        ? Get.find<UserStore>().user.value?.coinCount ?? 0
        : 0;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => PostCoinAnimatorDialog(
        initialBalance: balance,
        onTip: (count) async {
          await _controller.tipCoin(count);
          if (Get.isRegistered<UserStore>()) {
            Get.find<UserStore>().restoreSessionInBackground();
          }
        },
      ),
    );
  }

  Future<void> _requestCoinUnlock(PostDetail detail) async {
    if (!TokenManager.instance.hasToken) {
      final loggedIn = await Get.toNamed(AppRoutes.login);
      if (loggedIn == true && mounted) {
        await _controller.load(forceRefresh: true);
      }
      return;
    }

    final user = Get.isRegistered<UserStore>()
        ? Get.find<UserStore>().user.value
        : null;
    final balance = user?.goldBalance ?? 0;
    final action = await showDialog<LegacyAccessDialogAction>(
      context: context,
      builder: (context) => LegacyAccessDialog(
        price: detail.price,
        walletBalance: balance,
        nickname: user?.nickname ?? '',
        isVip: false,
      ),
    );
    if (!mounted || action == null) return;
    if (action == LegacyAccessDialogAction.purchase) {
      await _run(_controller.buy);
    } else if (action == LegacyAccessDialogAction.recharge) {
      await Get.toNamed<void>(AppRoutes.recharge);
    } else if (action == LegacyAccessDialogAction.charge) {
      await _openChargeUserPage(detail);
    }
  }

  Future<void> _showVipUnlockDialog(PostDetail detail) async {
    final user = Get.isRegistered<UserStore>()
        ? Get.find<UserStore>().user.value
        : null;
    final action = await showDialog<LegacyAccessDialogAction>(
      context: context,
      builder: (context) => LegacyAccessDialog(
        price: detail.price,
        walletBalance: user?.goldBalance ?? 0,
        nickname: user?.nickname ?? '',
        isVip: true,
      ),
    );
    if (!mounted || action == null) return;
    if (action == LegacyAccessDialogAction.vip) {
      await Get.toNamed<void>(AppRoutes.vipCenter);
    } else if (action == LegacyAccessDialogAction.login) {
      final loggedIn = await Get.toNamed(AppRoutes.login);
      if (loggedIn == true && mounted) {
        await _controller.load(forceRefresh: true);
      }
    } else if (action == LegacyAccessDialogAction.charge) {
      await _openChargeUserPage(detail);
    }
  }

  Future<void> _share(PostDetail detail) async {
    final rawValue = detail.shareUrl.trim();
    if (rawValue.isEmpty) {
      showToast('暂无可分享的链接', type: ToastType.warning);
      return;
    }
    var value = rawValue;
    final user = Get.isRegistered<UserStore>()
        ? Get.find<UserStore>().user.value
        : null;
    final shareUri = Uri.tryParse(rawValue);
    if (user != null && shareUri != null) {
      value = shareUri
          .replace(
            queryParameters: <String, String>{
              ...shareUri.queryParameters,
              'code': user.invitationCode,
              'share_code': '${user.id}',
            },
          )
          .toString();
    }
    try {
      await Clipboard.setData(ClipboardData(text: value));
      showToast('分享链接已复制', type: ToastType.success);
    } catch (_) {
      showToast('复制分享链接失败', type: ToastType.error);
    }
  }

  Future<void> _openPrivateMessage(PostAuthor author) async {
    if (author.id <= 0) {
      showToast('用户信息无效，暂时无法私信', type: ToastType.error);
      return;
    }
    if (!TokenManager.instance.hasToken) {
      final loggedIn = await Get.toNamed(AppRoutes.login);
      if (loggedIn != true || !mounted) return;
    }
    await Get.toNamed<void>(
      AppRoutes.messageChat,
      arguments: MessageMember(
        id: author.id,
        nickname: author.nickname,
        avatarUrl: author.avatarUrl,
      ),
    );
  }

  Future<void> _selectPlaybackLine() async {
    try {
      await _videoPlayerController.selectLine();
    } catch (_) {
      showToast('播放器尚未就绪', type: ToastType.warning);
    }
  }

  Future<void> _showRewardSheet() async {
    try {
      final products = await _controller.loadRewardProducts();
      if (!mounted || products.isEmpty) {
        if (TokenManager.instance.hasToken) {
          showToast('暂无可用的打赏选项', type: ToastType.warning);
        }
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            PostRewardSheet(products: products, onReward: _controller.reward),
      );
    } catch (_) {
      showToast('打赏选项加载失败', type: ToastType.error);
    }
  }

  Future<void> _showFeedbackSheet() async {
    try {
      final reasons = await _controller.loadFeedbackReasons();
      if (!mounted || reasons.isEmpty) {
        if (TokenManager.instance.hasToken) {
          showToast('暂无可用的反馈原因', type: ToastType.warning);
        }
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PostFeedbackSheet(
          reasons: reasons,
          onSubmit: (reason, content) =>
              _controller.sendFeedback(reason: reason, content: content),
        ),
      );
    } catch (_) {
      showToast('反馈原因加载失败', type: ToastType.error);
    }
  }

  Future<bool> _openExternalUrl(
    String value, {
    String fallbackMessage = '无法打开链接',
  }) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      showToast(fallbackMessage, type: ToastType.error);
      return false;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) showToast(fallbackMessage, type: ToastType.error);
      return opened;
    } catch (_) {
      showToast(fallbackMessage, type: ToastType.error);
      return false;
    }
  }

  String _resolveHtmlImages(String html) {
    final imagePattern = RegExp(
      r'''(<img\b[^>]*?\bsrc\s*=\s*["'])([^"']+)(["'])''',
      caseSensitive: false,
    );
    return html.replaceAllMapped(imagePattern, (match) {
      final url = LegacyNetworkImage.resolveUrl(match.group(2) ?? '');
      return '${match.group(1)}$url${match.group(3)}';
    });
  }

  @override
  void dispose() {
    _informationScrollController.dispose();
    _commentsScrollController
      ..removeListener(_handleCommentsScroll)
      ..dispose();
    _pageController.dispose();
    _commentInputController.dispose();
    _barrageInputController.dispose();
    _commentFocusNode.dispose();
    _barrageFocusNode.dispose();
    _commentsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final detail = _controller.detail;
        if (detail != null) _scheduleRegistrationPrompt(detail);
        final immersive = detail != null && _isImmersiveVideoDetail(detail);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.pageBackground,
          appBar: immersive
              ? null
              : LegacyAppBar(title: detail?.title ?? '内容详情'),
          body: immersive
              ? SafeArea(bottom: false, child: _buildBody(detail))
              : _buildBody(detail),
          bottomNavigationBar: _selectedTab == 1 && detail != null
              ? AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: PostCommentInput(
                    controller: _commentInputController,
                    focusNode: _commentFocusNode,
                    replyTo: _replyTo,
                    submitting: _commentsController.submitting,
                    onCancelReply: _cancelReply,
                    onSend: () => unawaited(_sendComment()),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(PostDetail? detail) {
    if (_controller.loading && detail == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }
    if (detail == null) {
      return _ErrorView(
        onRetry: () => unawaited(_controller.load().catchError((_) {})),
      );
    }

    final showPlayer =
        detail.type != 2 && (detail.coverUrl.isNotEmpty || detail.hasVideo);
    return Column(
      children: <Widget>[
        if (showPlayer)
          SizedBox(
            height: 206,
            child: _buildCover(
              detail,
              showBackButton: _isImmersiveVideoDetail(detail),
            ),
          ),
        SizedBox(
          height: 41,
          child: _DetailTabHeader(
            selectedIndex: _selectedTab,
            onSelected: _selectTab,
            barrageController: _barrageInputController,
            barrageFocusNode: _barrageFocusNode,
            commonBarrages: _commonBarrages,
            loadingCommonBarrages: _loadingCommonBarrages,
            showBarrageInput:
                detail.type == 1 &&
                detail.hasVideo &&
                !(detail.requiresRegistration &&
                    !TokenManager.instance.hasToken) &&
                !detail.requiresCoinUnlock &&
                !detail.requiresVipUnlock,
            sendingBarrage: _sendingBarrage,
            onSendBarrage: () => unawaited(_sendBarrage()),
            onCommonBarrageSelected: (content) =>
                unawaited(_sendBarrage(content)),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            children: <Widget>[
              _buildInformationTab(detail),
              _buildCommentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationTab(PostDetail detail) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refreshTab(0),
      child: CustomScrollView(
        key: PageStorageKey<String>('post_information_${widget.postId}'),
        controller: _informationScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          ..._buildContentPrelude(detail),
          ..._buildInformationSlivers(detail),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refreshTab(1),
      child: CustomScrollView(
        key: PageStorageKey<String>('post_comments_${widget.postId}'),
        controller: _commentsScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _buildCommentSlivers(),
      ),
    );
  }

  bool _isImmersiveVideoDetail(PostDetail detail) {
    return detail.type == 1 || detail.collectionType == 1;
  }

  List<Widget> _buildContentPrelude(PostDetail detail) {
    if (_isImmersiveVideoDetail(detail)) return const <Widget>[];
    final contentUnlocked =
        !detail.requiresCoinUnlock && !detail.requiresVipUnlock;
    return <Widget>[
      if (detail.description.trim().length >= 10)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          sliver: SliverToBoxAdapter(
            child: HtmlWidget(
              _resolveHtmlImages(detail.description),
              textStyle: const TextStyle(fontSize: 13, height: 1.55),
              onTapUrl: _openExternalUrl,
            ),
          ),
        ),
      if (contentUnlocked &&
          detail.collectionType != 1 &&
          detail.htmlContent.trim().isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: HtmlWidget(
              _resolveHtmlImages(detail.htmlContent),
              textStyle: const TextStyle(fontSize: 13, height: 1.55),
              onTapUrl: _openExternalUrl,
            ),
          ),
        ),
      if (contentUnlocked && detail.type == 2)
        SliverList.builder(
          itemCount: detail.imageContent.length,
          itemBuilder: (context, index) => LegacyNetworkImage(
            url: detail.imageContent[index],
            fit: BoxFit.fitWidth,
          ),
        ),
      if (!contentUnlocked && (detail.type == 2 || !detail.hasVideo))
        SliverToBoxAdapter(
          child: SizedBox(
            height: 206,
            child: _LockedContentPreview(
              detail: detail,
              submitting: _controller.isSubmitting('buy'),
              onUnlock: () => unawaited(
                detail.requiresVipUnlock
                    ? _showVipUnlockDialog(detail)
                    : _requestCoinUnlock(detail),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildInformationSlivers(PostDetail detail) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        sliver: SliverList.list(
          children: <Widget>[
            PostAuthorHeader(
              author: detail.author,
              submitting: _controller.isSubmitting('follow'),
              onOpenProfile: detail.author.id > 0
                  ? () => Get.toNamed<void>(
                      AppRoutes.userProfilePath(detail.author.id),
                    )
                  : null,
              onMessage: () => unawaited(_openPrivateMessage(detail.author)),
              onFollow: () => unawaited(_run(_controller.toggleFollow)),
            ),
            Text(
              detail.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (detail.labels.isNotEmpty) ...<Widget>[
              const SizedBox(height: 9),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: detail.labels
                    .where((item) => item.id > 0 && item.name.isNotEmpty)
                    .map(
                      (item) => _PostLabelChip(
                        label: item.name,
                        onTap: () => Get.toNamed(
                          AppRoutes.postLabelPath(item.id),
                          arguments: item,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 10),
            _PostStatistics(detail: detail),
            if (detail.advertisements.isNotEmpty) ...<Widget>[
              const SizedBox(height: 5),
              for (final advertisement in detail.advertisements)
                _buildAdvertisement(advertisement),
            ],
            PostActionBar(
              detail: detail,
              isSubmitting: _controller.isSubmitting,
              onLike: () => unawaited(_run(_controller.toggleLike)),
              onCollect: () => unawaited(_run(_controller.toggleCollect)),
              onCoin: () => unawaited(_selectCoinCount()),
              onLine: () => unawaited(_selectPlaybackLine()),
              onFeedback: () => unawaited(_showFeedbackSheet()),
              onShare: () => unawaited(_share(detail)),
            ),
            if (detail.requiresCoinUnlock)
              _PurchasePanel(
                price: detail.price,
                submitting: _controller.isSubmitting('buy'),
                onBuy: () => unawaited(_requestCoinUnlock(detail)),
              ),
            const SizedBox(height: 10),
            _PostSupportActions(
              recommending: _controller.isSubmitting('recommend'),
              rewarding: _controller.isSubmitting('reward'),
              onRecommend: () => unawaited(_run(_controller.highlyRecommend)),
              onReward: () => unawaited(_showRewardSheet()),
            ),
            if (_controller.showEpisodeSection) ...[
              const SizedBox(height: 18),
              _PostEpisodeSection(
                currentId: detail.id,
                items: _controller.episodes,
                currentPage: _controller.episodePage,
                totalItems: _controller.episodeTotal,
                loading: _controller.episodesLoading,
                switching: _controller.isSubmitting('episode'),
                onPageSelected: (page) =>
                    unawaited(_controller.loadEpisodePage(page)),
                onSelected: (episode) =>
                    unawaited(_run(() => _controller.selectEpisode(episode))),
              ),
            ],
          ],
        ),
      ),
      if (_controller.detailAdvertisements.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          sliver: SliverList.builder(
            itemCount: _controller.detailAdvertisements.length,
            itemBuilder: (context, index) => _buildDetailAdvertisement(
              _controller.detailAdvertisements[index],
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 5),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              const Text(
                '热门推荐',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _controller.recommendationsLoading
                    ? null
                    : () => unawaited(_run(_controller.refreshRecommendations)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: _controller.recommendationsLoading
                    ? const SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('换一批', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
      if (_controller.recommendations.isEmpty)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                _controller.recommendationsLoading ? '推荐加载中...' : '暂无推荐内容',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        )
      else
        SliverList.builder(
          itemCount: _controller.recommendations.length,
          itemBuilder: (context, index) =>
              _PostRecommendationCard(post: _controller.recommendations[index]),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  List<Widget> _buildCommentSlivers() {
    if (_commentsController.loading && _commentsController.items.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      ];
    }
    if (_commentsController.items.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CommentsMessage(
            failed: _commentsController.error != null,
            onRetry: () => unawaited(
              _commentsController.load(forceRefresh: true).catchError((_) {}),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 16, 10, 5),
          child: Text(
            '全部评论',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      SliverList.builder(
        itemCount: _commentsController.items.length,
        itemBuilder: (context, index) => PostCommentItem(
          comment: _commentsController.items[index],
          onReply: _reply,
        ),
      ),
      SliverToBoxAdapter(child: _buildCommentsFooter()),
    ];
  }

  Widget _buildCommentsFooter() {
    if (_commentsController.loadingMore) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (_commentsController.loadMoreError != null) {
      return SizedBox(
        height: 44,
        child: Center(
          child: TextButton(
            onPressed: () => unawaited(_loadMoreComments()),
            child: const Text('加载失败，点击重试'),
          ),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: Center(
        child: Text(
          _commentsController.hasMore ? '继续上滑加载更多' : '没有更多评论了',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildCover(PostDetail detail, {required bool showBackButton}) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PostVideoPlayer(
          key: ValueKey<String>('post_video_${detail.id}'),
          detail: detail,
          controller: _videoPlayerController,
          onLoginRequired: () => unawaited(_requestLoginForVideo()),
          onCoinUnlockRequired: () => unawaited(_requestCoinUnlock(detail)),
          onVipUnlockRequired: () => unawaited(_showVipUnlockDialog(detail)),
        ),
        if (showBackButton)
          Positioned(
            left: 8,
            top: 5,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: '返回',
                onPressed: () => Navigator.of(context).maybePop(),
                color: Colors.white,
                iconSize: 20,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdvertisement(PostAdvertisement advertisement) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: advertisement.targetUrl.isEmpty
          ? null
          : () => unawaited(
              _openExternalUrl(
                advertisement.targetUrl,
                fallbackMessage: '广告链接无法打开',
              ),
            ),
      child: SizedBox(
        height: 90,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: LegacyNetworkImage(
                url: advertisement.imageUrl,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Positioned(
              right: 0,
              bottom: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Text(
                    '广告',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAdvertisement(BannerItem advertisement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_openDetailAdvertisement(advertisement)),
        child: SizedBox(
          height: 80,
          child: LegacyNetworkImage(
            url: advertisement.pictureUrl,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetailAdvertisement(BannerItem advertisement) async {
    unawaited(
      PostApi.recordAdvertisementClick(
        advertisement.advertiseOrderId,
      ).catchError((_) {}),
    );
    if (advertisement.html.trim().isNotEmpty) {
      await Get.to<void>(
        () => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: LegacyAppBar(
            title: advertisement.name.trim().isEmpty
                ? '广告详情'
                : advertisement.name,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: HtmlWidget(
              _resolveHtmlImages(advertisement.html),
              onTapUrl: _openExternalUrl,
            ),
          ),
        ),
      );
      return;
    }
    final target = advertisement.outsideUrl.trim().isNotEmpty
        ? advertisement.outsideUrl
        : advertisement.insideUrl;
    if (target.trim().isEmpty) {
      showToast('该广告暂无可打开的内容', type: ToastType.warning);
      return;
    }
    await _openExternalUrl(target, fallbackMessage: '广告链接无法打开');
  }
}

class _LockedContentPreview extends StatelessWidget {
  const _LockedContentPreview({
    required this.detail,
    required this.submitting,
    required this.onUnlock,
  });

  final PostDetail detail;
  final bool submitting;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        LegacyNetworkImage(url: detail.coverUrl),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: submitting ? null : onUnlock,
          child: ColoredBox(
            color: Colors.black38,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail.requiresVipUnlock
                        ? '当前内容需开通VIP，点我立即购买！'
                        : '当前内容需付费${_formatPrice(detail.price)}金币购买，点我立即购买！',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (detail.requiresCoinUnlock)
                    Text(
                      '已购买人数：${detail.salesCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatPrice(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }
}

class _PostSupportActions extends StatelessWidget {
  const _PostSupportActions({
    required this.recommending,
    required this.rewarding,
    required this.onRecommend,
    required this.onReward,
  });

  final bool recommending;
  final bool rewarding;
  final VoidCallback onRecommend;
  final VoidCallback onReward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: recommending ? null : onRecommend,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
              ),
              icon: recommending
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : SvgPicture.asset(
                      'assets/images/ic_post_reward.svg',
                      width: 16,
                      height: 16,
                    ),
              label: const Text('强烈推荐', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: rewarding ? null : onReward,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
              ),
              icon: rewarding
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/images/ic_post_gift.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
              label: const Text('帖子打赏', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PostEpisodeSection extends StatelessWidget {
  const _PostEpisodeSection({
    required this.currentId,
    required this.items,
    required this.currentPage,
    required this.totalItems,
    required this.loading,
    required this.switching,
    required this.onPageSelected,
    required this.onSelected,
  });

  final int currentId;
  final List<PostSummary> items;
  final int currentPage;
  final int totalItems;
  final bool loading;
  final bool switching;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<PostSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    final pageCount = (totalItems / 10).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('选集', style: TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              totalItems > 0 ? '更新到第$totalItems话' : '选集加载中',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 12,
            ),
          ],
        ),
        if (pageCount > 1) ...<Widget>[
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pageCount,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final page = index + 1;
                final end = ((index + 1) * 10).clamp(0, totalItems);
                return InkWell(
                  onTap: loading ? null : () => onPageSelected(page),
                  child: Text(
                    '${index * 10 + 1}-$end',
                    style: TextStyle(
                      color: page == currentPage
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: loading && items.isEmpty
              ? const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = item.id == currentId;
                    return SizedBox(
                      width: 140,
                      child: InkWell(
                        onTap: switching ? null : () => onSelected(item),
                        borderRadius: BorderRadius.circular(10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 0.5,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 9, 8, 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        if (selected) ...<Widget>[
                                          SvgPicture.asset(
                                            'assets/images/v1/ic_post_collect_tag.svg',
                                            width: 14,
                                            height: 14,
                                          ),
                                          const SizedBox(width: 5),
                                        ],
                                        Text(
                                          '第${(currentPage - 1) * 10 + index + 1}话',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.accessBadgeText.isNotEmpty)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: PostAccessBadge(
                                    text: item.accessBadgeText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PostRecommendationCard extends StatelessWidget {
  const _PostRecommendationCard({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverWidth = math.min(175.0, constraints.maxWidth * 0.48);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  height: 98,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: coverWidth,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            LegacyNetworkImage(
                              url: post.coverUrls.isEmpty
                                  ? post.preferredCoverUrl
                                  : post.coverUrls.first,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            if (post.accessBadgeText.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: PostAccessBadge(
                                  text: post.accessBadgeText,
                                ),
                              ),
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    _formatVideoDuration(post.durationSeconds),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _RecommendationInformation(post: post)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Divider(height: 0.5, color: AppColors.divider),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecommendationInformation extends StatelessWidget {
  const _RecommendationInformation({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.35),
        ),
        const Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFF6633).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              '${_compactNumber(post.collectCount)}点赞',
              style: const TextStyle(color: Color(0xFFFF6633), fontSize: 9),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textTertiary, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  'UP',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 8),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                post.authorNickname.isEmpty
                    ? post.categoryName
                    : post.authorNickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/ic_video_play.svg',
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                AppColors.textTertiary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _compactNumber(post.viewCount),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
            const Text(
              '  ·  ',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
            ),
            Expanded(
              child: Text(
                _recommendationTime(post.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showToast('更多操作模块正在重构', type: ToastType.info),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _formatVideoDuration(int seconds) {
  final safe = seconds.clamp(0, 864000);
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}

String _compactNumber(int value) {
  if (value < 10000) return '$value';
  final number = value / 10000;
  return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}万';
}

String _recommendationTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final difference = DateTime.now().difference(local).abs();
  if (difference.inMinutes < 5) return '刚刚';
  if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
  if (difference.inDays < 1) return '${difference.inHours}小时前';
  if (difference.inDays < 7) return '${difference.inDays}天前';
  if (difference.inDays < 8) return '1周前';
  if (difference.inDays < 30) return '${difference.inDays}天前';
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

class _PostStatistics extends StatelessWidget {
  const _PostStatistics({required this.detail});

  final PostDetail detail;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11),
        children: <InlineSpan>[
          const TextSpan(
            text: '购买：',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          TextSpan(text: '${detail.salesCount}'),
          const TextSpan(
            text: '   浏览：',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          TextSpan(text: '${detail.viewCount}'),
          const TextSpan(
            text: '   收藏：',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          TextSpan(text: '${detail.collectCount}'),
        ],
      ),
    );
  }
}

class _DetailTabHeader extends StatelessWidget {
  const _DetailTabHeader({
    required this.selectedIndex,
    required this.onSelected,
    required this.barrageController,
    required this.barrageFocusNode,
    required this.commonBarrages,
    required this.loadingCommonBarrages,
    required this.showBarrageInput,
    required this.sendingBarrage,
    required this.onSendBarrage,
    required this.onCommonBarrageSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final TextEditingController barrageController;
  final FocusNode barrageFocusNode;
  final List<CommonBarrage> commonBarrages;
  final bool loadingCommonBarrages;
  final bool showBarrageInput;
  final bool sendingBarrage;
  final VoidCallback onSendBarrage;
  final ValueChanged<String> onCommonBarrageSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          _DetailTab(
            label: '简介',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _DetailTab(
            label: '评论',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          const Spacer(),
          if (showBarrageInput)
            _BarrageComposer(
              controller: barrageController,
              focusNode: barrageFocusNode,
              commonBarrages: commonBarrages,
              loadingCommonBarrages: loadingCommonBarrages,
              submitting: sendingBarrage,
              onSend: onSendBarrage,
              onCommonBarrageSelected: onCommonBarrageSelected,
            ),
          if (showBarrageInput) const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _BarrageComposer extends StatefulWidget {
  const _BarrageComposer({
    required this.controller,
    required this.focusNode,
    required this.commonBarrages,
    required this.loadingCommonBarrages,
    required this.submitting,
    required this.onSend,
    required this.onCommonBarrageSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CommonBarrage> commonBarrages;
  final bool loadingCommonBarrages;
  final bool submitting;
  final VoidCallback onSend;
  final ValueChanged<String> onCommonBarrageSelected;

  @override
  State<_BarrageComposer> createState() => _BarrageComposerState();
}

class _BarrageComposerState extends State<_BarrageComposer> {
  final GlobalKey _anchorKey = GlobalKey();

  Future<void> _showCommonBarrageList() async {
    if (widget.loadingCommonBarrages) {
      showToast('常用弹幕加载中', type: ToastType.info);
      return;
    }
    if (widget.commonBarrages.isEmpty) {
      showToast('暂无常用弹幕', type: ToastType.info);
      return;
    }
    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final content = await showPostCommonBarrageList(
      context: context,
      anchor: renderBox,
      barrages: widget.commonBarrages,
    );
    if (content != null && content.isNotEmpty && mounted) {
      widget.onCommonBarrageSelected(content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _anchorKey,
      width: 180,
      height: 30,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.submitting,
              maxLength: 50,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: '发送弹幕',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              if (value.text.trim().isNotEmpty) return const SizedBox.shrink();
              return SizedBox(
                width: 24,
                height: 30,
                child: IconButton(
                  onPressed: widget.submitting
                      ? null
                      : () => unawaited(_showCommonBarrageList()),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  color: AppColors.textPrimary,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              );
            },
          ),
          SizedBox(
            width: 44,
            height: 30,
            child: FilledButton(
              onPressed: widget.submitting ? null : widget.onSend,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: widget.submitting
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : const Text('发送', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 28 : 0,
              height: 2,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsMessage extends StatelessWidget {
  const _CommentsMessage({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            failed ? '评论加载失败' : '还没有评论，来说点什么吧',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          if (failed) TextButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}

class _PostLabelChip extends StatelessWidget {
  const _PostLabelChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '#$label',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({
    required this.price,
    required this.submitting,
    required this.onBuy,
  });

  final double price;
  final bool submitting;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '本内容需要 ${price.toStringAsFixed(0)} 金币',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 72,
            height: 30,
            child: FilledButton(
              onPressed: submitting ? null : onBuy,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.primary,
              ),
              child: submitting
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : const Text('立即购买', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            '内容详情加载失败',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          TextButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}
