import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/user_profile.dart';
import 'package:b_flutter/pages/home/components/home_latest_post_card.dart';
import 'package:b_flutter/pages/posts/components/user_profile_post_card.dart';
import 'package:b_flutter/pages/posts/charge_user_page.dart';
import 'package:b_flutter/pages/posts/user_profile_video_page.dart';
import 'package:b_flutter/pages/topics/components/topic_post_card.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userId});

  final int userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  UserProfile? _profile;
  Object? _error;
  bool _loading = true;
  bool _following = false;
  late final TabController _tabController;
  late final bool _isCurrentUser;

  @override
  void initState() {
    super.initState();
    final currentUser =
        Get.isRegistered<UserStore>() ? Get.find<UserStore>().user.value : null;
    _isCurrentUser = currentUser?.id == widget.userId && widget.userId > 0;
    _tabController = TabController(
      length: _isCurrentUser ? 3 : 2,
      vsync: this,
      initialIndex: _isCurrentUser ? 0 : 0,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await PostApi.getUserProfile(
        userId: widget.userId,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _following) return;
    if (!TokenManager.instance.hasToken) {
      showToast('请先登录后再关注', type: ToastType.warning);
      await Get.toNamed<void>(AppRoutes.login);
      return;
    }
    setState(() => _following = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => UserApi.toggleFollow(userId: profile.id),
        loadingMessage: profile.isFollowing ? '取消关注中...' : '关注中...',
        successMessage: profile.isFollowing ? '已取消关注' : '关注成功',
      );
      if (mounted) {
        setState(
          () => _profile = profile.copyWith(isFollowing: !profile.isFollowing),
        );
      }
    } catch (_) {
      // SubmissionFeedback has already shown the request result.
    } finally {
      if (mounted) setState(() => _following = false);
    }
  }

  Future<void> _openMessage() async {
    final profile = _profile;
    if (profile == null || profile.id <= 0) return;
    if (!TokenManager.instance.hasToken) {
      await Get.toNamed<void>(AppRoutes.login);
      return;
    }
    await Get.toNamed<void>(
      AppRoutes.messageChat,
      arguments: MessageMember(
        id: profile.id,
        nickname: profile.nickname,
        avatarUrl: profile.avatarUrl,
      ),
    );
  }

  Future<void> _openCharge() async {
    final profile = _profile;
    if (profile == null || profile.id <= 0) return;
    await Get.to<void>(
      () => ChargeUserPage(
        authorId: profile.id,
        fallbackAuthor: PostAuthor(
          id: profile.id,
          nickname: profile.nickname,
          avatarUrl: profile.avatarUrl,
          signature: profile.signature,
          fanCount: profile.fanCount,
          workCount: profile.workCount,
          isFollowing: profile.isFollowing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? _emptyProfile(widget.userId);
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: LayoutBuilder(
        builder: (context, constraints) => _loading && _profile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null && _profile == null
                ? _ProfileError(
                    error: _error,
                    onRetry: () => unawaited(_load(forceRefresh: true)),
                  )
                : UserProfileScrollLayout(
                    controller: _tabController,
                    isCurrentUser: _isCurrentUser,
                    headerExtent: UserProfileHeader.extentFor(
                      context,
                      profile,
                      width: constraints.maxWidth,
                    ),
                    onBack: Get.back<void>,
                    onMessage:
                        _isCurrentUser ? null : () => unawaited(_openMessage()),
                    onSearch: () => Get.toNamed<void>(AppRoutes.search),
                    header: UserProfileHeader(
                      profile: profile,
                      isCurrentUser: _isCurrentUser,
                      following: _following,
                      onFollow: () => unawaited(_toggleFollow()),
                      onMessage: () => unawaited(_openMessage()),
                      onCharge: () => unawaited(_openCharge()),
                      onEdit: () => Get.toNamed<void>(AppRoutes.personalInfo),
                      showNavigation: false,
                    ),
                    children: <Widget>[
                      if (_isCurrentUser)
                        _UserHighlightsTab(userId: widget.userId),
                      _UserPostsTab(
                        userId: widget.userId,
                        type: _UserPostsType.dynamic,
                      ),
                      _UserPostsTab(
                        userId: widget.userId,
                        type: _UserPostsType.manuscript,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class UserProfileScrollLayout extends StatelessWidget {
  const UserProfileScrollLayout({
    super.key,
    required this.controller,
    required this.isCurrentUser,
    required this.header,
    required this.children,
    required this.onBack,
    required this.onSearch,
    this.headerExtent = 300,
    this.onMessage,
  });

  final TabController controller;
  final bool isCurrentUser;
  final Widget header;
  final List<Widget> children;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final double headerExtent;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final expandedHeight = headerExtent + 58 - safeTop;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          expandedHeight: expandedHeight,
          toolbarHeight: 56,
          elevation: innerBoxIsScrolled ? 1 : 0,
          backgroundColor: AppColors.surfaceMuted,
          leadingWidth: 64,
          leading: Align(
            alignment: Alignment.centerRight,
            child: _HeaderRoundButton(
              icon: CupertinoIcons.chevron_back,
              iconSize: 21,
              onTap: onBack,
            ),
          ),
          actions: <Widget>[
            if (onMessage != null) ...<Widget>[
              _HeaderRoundButton(
                onTap: onMessage,
                child: SvgPicture.asset(
                  'assets/images/ic_topic_comment.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            _HeaderRoundButton(
              icon: CupertinoIcons.search,
              iconSize: 20,
              onTap: onSearch,
            ),
            const SizedBox(width: 8),
            const _HeaderRoundButton(
              icon: CupertinoIcons.ellipsis_vertical,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: header,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: _ProfileTabBar(
              controller: controller,
              isCurrentUser: isCurrentUser,
            ),
          ),
        ),
      ],
      body: TabBarView(controller: controller, children: children),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.controller, required this.isCurrentUser});

  final TabController controller;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            key: const ValueKey<String>('user_profile_tabs'),
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: controller,
              indicator: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelColor: AppColors.textPrimary,
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: <Tab>[
                if (isCurrentUser) const Tab(text: '主页'),
                const Tab(text: '动态'),
                const Tab(text: '投稿'),
              ],
            ),
          ),
        ),
      );
}

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({
    super.key,
    required this.profile,
    required this.isCurrentUser,
    required this.following,
    required this.onFollow,
    required this.onMessage,
    required this.onCharge,
    required this.onEdit,
    this.showNavigation = true,
  });

  final UserProfile profile;
  final bool isCurrentUser;
  final bool following;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onCharge;
  final VoidCallback onEdit;
  final bool showNavigation;

  static const double _cardTop = 112;
  static const double _gapBelowCard = 8;
  static const TextStyle _nicknameStyle = TextStyle(
    inherit: false,
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle _idStyle = TextStyle(
    inherit: false,
    fontSize: 11,
    color: AppColors.textTertiary,
  );
  static const TextStyle _signatureStyle = TextStyle(
    inherit: false,
    height: 1.3,
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const TextStyle _metricValueStyle = TextStyle(
    inherit: false,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _metricLabelStyle = TextStyle(
    inherit: false,
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static double extentFor(
    BuildContext context,
    UserProfile profile, {
    double? width,
  }) {
    final layoutWidth = width != null && width.isFinite
        ? width
        : MediaQuery.sizeOf(context).width;
    final availableTextWidth = layoutWidth - 116;
    final maxTextWidth = availableTextWidth > 1 ? availableTextWidth : 1.0;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final signature =
        profile.signature.isEmpty ? '这个人很神秘，什么都没有写' : profile.signature;

    double textHeight(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxTextWidth);
      return painter.height;
    }

    final textColumnHeight = textHeight(
          profile.nickname.isEmpty ? '未设置昵称' : profile.nickname,
          _nicknameStyle,
          maxLines: 1,
        ) +
        3 +
        textHeight('ID：${profile.id}', _idStyle, maxLines: 1) +
        4 +
        textHeight(signature, _signatureStyle);
    final rowHeight = textColumnHeight > 58 ? textColumnHeight : 58.0;
    final metricHeight = textHeight('0', _metricValueStyle, maxLines: 1) +
        2 +
        textHeight('粉丝', _metricLabelStyle, maxLines: 1);
    // TextPainter reports fractional glyph metrics while the render boxes snap
    // both text groups to physical pixels, so retain two logical pixels here.
    final cardHeight = 24 + 2 + rowHeight + 8 + 1 + 6 + metricHeight + 7 + 38;
    return _cardTop + cardHeight + _gapBelowCard;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final safeTop = MediaQuery.paddingOf(context).top;
          final headerExtent = extentFor(
            context,
            profile,
            width: constraints.maxWidth,
          );
          return SizedBox(
            height: headerExtent,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      profile.backgroundUrl.isEmpty
                          ? Image.asset(
                              'assets/images/v1/bg_user_detail.png',
                              fit: BoxFit.cover,
                            )
                          : LegacyNetworkImage(url: profile.backgroundUrl),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[Colors.black26, Colors.transparent],
                            stops: <double>[0, .7],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showNavigation)
                  Positioned(
                    top: safeTop + 10,
                    left: 12,
                    child: _HeaderRoundButton(
                      icon: CupertinoIcons.chevron_back,
                      iconSize: 21,
                      onTap: Get.back<void>,
                    ),
                  ),
                if (showNavigation)
                  Positioned(
                    top: safeTop + 10,
                    right: 12,
                    child: Row(
                      children: <Widget>[
                        if (!isCurrentUser) ...<Widget>[
                          _HeaderRoundButton(
                            onTap: onMessage,
                            child: SvgPicture.asset(
                              'assets/images/ic_topic_comment.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        _HeaderRoundButton(
                          icon: CupertinoIcons.search,
                          onTap: () => Get.toNamed<void>(AppRoutes.search),
                        ),
                        const SizedBox(width: 10),
                        const _HeaderRoundButton(
                          icon: CupertinoIcons.ellipsis_vertical,
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: _cardTop,
                  left: 12,
                  right: 12,
                  child: Container(
                    key: const ValueKey<String>('user_profile_card'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 58,
                              height: 58,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(.3),
                                ),
                              ),
                              child: LegacyNetworkImage(
                                url: profile.avatarUrl,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    profile.nickname.isEmpty
                                        ? '未设置昵称'
                                        : profile.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _nicknameStyle,
                                  ),
                                  const SizedBox(height: 3),
                                  Text('ID：${profile.id}', style: _idStyle),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.signature.isEmpty
                                        ? '这个人很神秘，什么都没有写'
                                        : profile.signature,
                                    style: _signatureStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _ProfileMetric(
                                label: '粉丝',
                                value: profile.fanCount,
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _ProfileMetric(
                                label: '作品',
                                value: profile.workCount,
                              ),
                            ),
                            _metricDivider(),
                            Expanded(
                              child: _ProfileMetric(
                                label: '获赞',
                                value: profile.likeCount,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          height: 38,
                          child: isCurrentUser
                              ? OutlinedButton.icon(
                                  onPressed: onEdit,
                                  style: _outlinedProfileButtonStyle(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                  ),
                                  icon: const Icon(CupertinoIcons.pencil,
                                      size: 15),
                                  label: const Text('编辑资料'),
                                )
                              : Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: onCharge,
                                        style: _outlinedProfileButtonStyle(),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            SvgPicture.asset(
                                              'assets/images/v1/ic_lightning.svg',
                                              width: 14,
                                              height: 14,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              profile.isSubscribed
                                                  ? '充电中'
                                                  : '充电',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: following ? null : onFollow,
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: following
                                            ? const SizedBox.square(
                                                dimension: 15,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 1.5,
                                                ),
                                              )
                                            : Text(
                                                profile.isFollowing
                                                    ? '已关注'
                                                    : '关注',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

ButtonStyle _outlinedProfileButtonStyle({
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) =>
    OutlinedButton.styleFrom(
      padding: padding,
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

class _HeaderRoundButton extends StatelessWidget {
  const _HeaderRoundButton({
    this.icon,
    this.iconSize = 16,
    this.child,
    this.onTap,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final double iconSize;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: child ?? Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _formatProfileCount(value),
            style: UserProfileHeader._metricValueStyle,
          ),
          const SizedBox(height: 2),
          Text(label, style: UserProfileHeader._metricLabelStyle),
        ],
      );
}

Widget _metricDivider() =>
    Container(width: 1, height: 24, color: AppColors.divider);

String _formatProfileCount(int value) {
  if (value > 1000000) return '${(value / 10000).toStringAsFixed(1)} 百万';
  if (value > 10000) return '${(value / 10000).toStringAsFixed(1)} w';
  if (value > 1000) {
    final count = value % 1000 == 0
        ? (value / 1000).toStringAsFixed(0)
        : (value / 1000).toStringAsFixed(1);
    return '$count k';
  }
  return '$value';
}

class _UserHighlightsTab extends StatefulWidget {
  const _UserHighlightsTab({required this.userId});

  final int userId;

  @override
  State<_UserHighlightsTab> createState() => _UserHighlightsTabState();
}

class _UserHighlightsTabState extends State<_UserHighlightsTab>
    with AutomaticKeepAliveClientMixin<_UserHighlightsTab> {
  Future<UserProfileHighlights>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = PostApi.getUserProfileHighlights(userId: widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = PostApi.getUserProfileHighlights(
        userId: widget.userId,
        forceRefresh: true,
      );
    });
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<UserProfileHighlights>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (!snapshot.hasData) {
          return _ProfileError(
            error: snapshot.error,
            onRetry: () => unawaited(_refresh()),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
            children: <Widget>[
              UserProfileHighlightSection(
                userId: widget.userId,
                type: UserProfileVideoType.liked,
                group: data.liked,
              ),
              UserProfileHighlightSection(
                userId: widget.userId,
                type: UserProfileVideoType.purchased,
                group: data.purchased,
              ),
              UserProfileHighlightSection(
                userId: widget.userId,
                type: UserProfileVideoType.collected,
                group: data.collected,
              ),
              UserProfileHighlightSection(
                userId: widget.userId,
                type: UserProfileVideoType.coined,
                group: data.coined,
              ),
            ],
          ),
        );
      },
    );
  }
}

class UserProfileHighlightSection extends StatelessWidget {
  const UserProfileHighlightSection({
    super.key,
    required this.userId,
    required this.type,
    required this.group,
  });

  final int userId;
  final UserProfileVideoType type;
  final UserProfileHighlightGroup group;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              key: ValueKey<String>(
                'user_profile_highlight_header_${type.apiValue}',
              ),
              children: <Widget>[
                Text(
                  type.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 7),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    child: Text(
                      '${group.count}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Get.toNamed<void>(
                    AppRoutes.userProfileVideos,
                    arguments: UserProfileVideoArguments(
                      userId: userId,
                      type: type,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '查看更多',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (group.posts.isEmpty)
              Container(
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '暂无数据',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              )
            else
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 160 / 145,
                ),
                itemBuilder: (context, index) =>
                    UserProfilePostCard(post: group.posts[index]),
              ),
          ],
        ),
      );
}

enum _UserPostsType { dynamic, manuscript }

class _UserPostsTab extends StatefulWidget {
  const _UserPostsTab({required this.userId, required this.type});

  final int userId;
  final _UserPostsType type;

  @override
  State<_UserPostsTab> createState() => _UserPostsTabState();
}

class _UserPostsTabState extends State<_UserPostsTab>
    with AutomaticKeepAliveClientMixin<_UserPostsTab> {
  final List<PostSummary> _posts = <PostSummary>[];
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  bool _loadMoreWhenNeeded(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 260) {
      unawaited(_loadMore());
    }
    return false;
  }

  Future<PagedResult<PostSummary>> _request(int page, bool forceRefresh) =>
      switch (widget.type) {
        _UserPostsType.dynamic => PostApi.getUserDynamics(
            userId: widget.userId,
            page: page,
            forceRefresh: forceRefresh,
          ),
        _UserPostsType.manuscript => PostApi.getUserManuscripts(
            userId: widget.userId,
            page: page,
            forceRefresh: forceRefresh,
          ),
      };

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _request(1, forceRefresh);
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page.items);
        _page = page.page == 0 ? 1 : page.page;
        _hasMore = page.hasMore && page.items.isNotEmpty;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _request(_page + 1, false);
      if (!mounted) return;
      final ids = _posts.map((post) => post.id).toSet();
      final appended =
          page.items.where((post) => post.id > 0 && ids.add(post.id)).toList();
      setState(() {
        _posts.addAll(appended);
        _page = page.page > _page ? page.page : _page + 1;
        _hasMore = page.hasMore && appended.isNotEmpty;
      });
    } catch (_) {
      if (mounted) showToast('加载更多失败，请稍后重试', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null && _posts.isEmpty) {
      return _ProfileError(
        error: _error,
        onRetry: () => unawaited(_load(forceRefresh: true)),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _loadMoreWhenNeeded,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(forceRefresh: true),
        child: _posts.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                children: <Widget>[
                  Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Text(
                      '暂无数据',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return _PostsFooter(
                      loading: _loadingMore,
                      hasMore: _hasMore,
                    );
                  }
                  return switch (widget.type) {
                    _UserPostsType.dynamic => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: TopicPostCard(post: _posts[index]),
                      ),
                    _UserPostsType.manuscript => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: HomeLatestPostCard(post: _posts[index]),
                      ),
                  };
                },
              ),
      ),
    );
  }
}

class _PostsFooter extends StatelessWidget {
  const _PostsFooter({required this.loading, required this.hasMore});

  final bool loading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: Center(
          child: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              : Text(
                  hasMore ? '上拉加载更多' : '没有更多了',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message =
        error is ApiException ? (error! as ApiException).message : '加载失败，请稍后重试';
    return Center(
      child: TextButton(onPressed: onRetry, child: Text('$message，点击重试')),
    );
  }
}

UserProfile _emptyProfile(int id) => UserProfile(
      id: id,
      nickname: '',
      avatarUrl: '',
      backgroundUrl: '',
      signature: '',
      fanCount: 0,
      workCount: 0,
      likeCount: 0,
      isFollowing: false,
      isSubscribed: false,
    );
