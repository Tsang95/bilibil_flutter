import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/message_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/pages/message/message_chat_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin<MessagePage> {
  final PageController _pageController = PageController();
  int _index = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openService() async {
    final url = AppConfigStore.instance.config?.onlineUrl.trim() ?? '';
    if (url.isEmpty) {
      showToast('客服信息暂未配置', type: ToastType.info);
      return;
    }
    final target = Uri.tryParse(url);
    if (target == null || !await launchUrl(target)) {
      showToast('客服链接打开失败', type: ToastType.error);
    }
  }

  void _select(int index) {
    setState(() => _index = index);
    unawaited(
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userStore = Get.find<UserStore>();
    return SafeArea(
      child: ColoredBox(
        color: AppColors.surface,
        child: Obx(() {
          final user = userStore.user.value;
          final sessionKey = ValueKey<bool>(userStore.isLoggedIn);
          return Column(
            children: <Widget>[
              SizedBox(
                height: 72,
                child: Row(
                  children: <Widget>[
                    _MessageTab(
                      label: '站内信',
                      asset: 'assets/images/ic_site_message.svg',
                      selected: _index == 0,
                      badge: user?.likeMessageCount ?? 0,
                      onTap: () => _select(0),
                    ),
                    _MessageTab(
                      label: '评论',
                      asset: 'assets/images/ic_site_commend.svg',
                      selected: _index == 1,
                      badge: user?.commentMessageCount ?? 0,
                      onTap: () => _select(1),
                    ),
                    _MessageTab(
                      label: '联系客服',
                      asset: 'assets/images/ic_site_server.svg',
                      selected: false,
                      badge: 0,
                      onTap: () => unawaited(_openService()),
                    ),
                  ],
                ),
              ),
              const Divider(height: .5),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: <Widget>[
                    KeyedSubtree(
                      key: sessionKey,
                      child: const _ConversationList(),
                    ),
                    KeyedSubtree(
                      key: sessionKey,
                      child: const _InteractionList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MessageTab extends StatelessWidget {
  const _MessageTab({
    required this.label,
    required this.asset,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              SvgPicture.asset(
                asset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  selected ? Colors.redAccent : AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: -10,
                  top: -7,
                  child: _MessageBadge(count: badge),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.redAccent : AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageBadge extends StatelessWidget {
  const _MessageBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      border: Border.all(color: Colors.white),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

class _ConversationList extends StatefulWidget {
  const _ConversationList();
  @override
  State<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<_ConversationList> {
  List<MessageConversation> _items = const <MessageConversation>[];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final loggedIn = Get.find<UserStore>().isLoggedIn;
    if (!loggedIn) {
      setState(() {
        _items = const <MessageConversation>[];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await MessageApi.getConversations(forceRefresh: true);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.find<UserStore>().isLoggedIn) return const _LoginRequired();
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) return _RetryView(onTap: _load);
    if (_items.isEmpty) return const _EmptyMessageView(label: '暂无站内信');
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        itemBuilder: (context, index) => _ConversationItem(item: _items[index]),
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  const _ConversationItem({required this.item});
  final MessageConversation item;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.contact.id <= 0
        ? null
        : () => Get.to<void>(() => MessageChatPage(contact: item.contact)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 48,
              child: LegacyNetworkImage(
                url: item.contact.avatarUrl,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.contact.nickname,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                _timeLabel(item.lastChatAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InteractionList extends StatefulWidget {
  const _InteractionList();
  @override
  State<_InteractionList> createState() => _InteractionListState();
}

class _InteractionListState extends State<_InteractionList> {
  final ScrollController _scrollController = ScrollController();
  final List<MessageInteraction> _items = <MessageInteraction>[];
  Object? _error;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) unawaited(_loadMore());
  }

  Future<void> _reload() async {
    _page = 1;
    _hasMore = true;
    await _loadMore(forceRefresh: true);
  }

  Future<void> _loadMore({bool forceRefresh = false}) async {
    if (_loading || !_hasMore || !Get.find<UserStore>().isLoggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await MessageApi.getInteractions(
        page: _page,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        if (_page == 1) _items.clear();
        final known = _items.map((item) => item.id).toSet();
        _items.addAll(page.items.where((item) => known.add(item.id)));
        _hasMore = page.hasMore;
        if (page.hasMore) _page++;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.find<UserStore>().isLoggedIn) return const _LoginRequired();
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) return _RetryView(onTap: _reload);
    if (_items.isEmpty) return const _EmptyMessageView(label: '暂无评论消息');
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _MessageLoadFooter(
              loading: _loading,
              hasMore: _hasMore,
              onRetry: _loadMore,
            );
          }
          return _InteractionItem(item: _items[index]);
        },
      ),
    );
  }
}

class _InteractionItem extends StatelessWidget {
  const _InteractionItem({required this.item});
  final MessageInteraction item;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.postId > 0
        ? () => Get.toNamed<void>(AppRoutes.postDetailPath(item.postId))
        : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.square(
            dimension: 48,
            child: LegacyNetworkImage(
              url: item.operator.avatarUrl,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.operator.nickname,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      _timeLabel(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: <InlineSpan>[
                      TextSpan(text: item.isComment ? '评论了你的作品' : '点赞了你的作品'),
                      TextSpan(
                        text: '《${item.postTitle}》',
                        style: const TextStyle(color: AppColors.info),
                      ),
                    ],
                  ),
                ),
                if (item.isComment) ...<Widget>[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.content,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => Get.toNamed<void>(AppRoutes.login),
      child: const Text('登录后查看消息', style: TextStyle(color: AppColors.primary)),
    ),
  );
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onTap});
  final Future<void> Function() onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => unawaited(onTap()),
      child: const Text('加载失败，点击重试'),
    ),
  );
}

class _EmptyMessageView extends StatelessWidget {
  const _EmptyMessageView({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      label,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
  );
}

class _MessageLoadFooter extends StatelessWidget {
  const _MessageLoadFooter({
    required this.loading,
    required this.hasMore,
    required this.onRetry,
  });
  final bool loading;
  final bool hasMore;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) {
      return TextButton(
        onPressed: () => unawaited(onRetry()),
        child: const Text('加载更多'),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          '没有更多消息',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

String _timeLabel(String raw) {
  final time = DateTime.tryParse(raw);
  if (time == null) return raw;
  final span = DateTime.now().difference(time);
  if (span.inMinutes < 1) return '刚刚';
  if (span.inHours < 1) return '${span.inMinutes}分钟前';
  if (span.inDays < 1) return '${span.inHours}小时前';
  if (span.inDays < 7) return '${span.inDays}天前';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}
