import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/pages/home/components/home_banner_carousel.dart';
import 'package:b_flutter/pages/game/game_detail_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with AutomaticKeepAliveClientMixin<GamePage> {
  List<BannerItem> _banners = const <BannerItem>[];
  List<GameCategory> _categories = const <GameCategory>[];
  int _balance = 0;
  int _selectedCategory = 0;
  Object? _error;
  bool _loading = true;
  bool _refreshingBalance = false;
  bool _showingLoginPrompt = false;
  int? _launchingGameId;
  late final Worker _userWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final userStore = Get.find<UserStore>();
    _userWorker = ever(userStore.user, (_) {
      if (!mounted) return;
      if (userStore.isLoggedIn) {
        unawaited(_load());
      } else {
        setState(() {
          _categories = const <GameCategory>[];
          _balance = 0;
          _error = null;
          _loading = false;
        });
        unawaited(_loadPublicContent());
      }
    });
    if (userStore.isLoggedIn) {
      unawaited(_load());
    } else {
      _loading = false;
      unawaited(_loadPublicContent());
    }
  }

  @override
  void dispose() {
    _userWorker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        GameApi.getBanners(forceRefresh: true),
        GameApi.getCategories(forceRefresh: true),
        _loadBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _banners = values[0] as List<BannerItem>;
        _categories = values[1] as List<GameCategory>;
        _balance = values[2] as int;
        _selectedCategory = 0;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPublicContent() async {
    try {
      final banners = await GameApi.getBanners();
      if (!mounted || Get.find<UserStore>().isLoggedIn) return;
      setState(() => _banners = banners);
    } catch (_) {
      // The bundled legacy banner remains visible when the public request fails.
    }
  }

  Future<int> _loadBalance() async {
    if (!Get.find<UserStore>().isLoggedIn) return 0;
    return GameApi.getBalance();
  }

  Future<void> _refreshBalance() async {
    if (_refreshingBalance) {
      return;
    }
    setState(() => _refreshingBalance = true);
    try {
      final balance = await _loadBalance();
      if (mounted) setState(() => _balance = balance);
    } catch (_) {
      // ApiClient keeps the current balance visible on failed silent refresh.
    } finally {
      if (mounted) setState(() => _refreshingBalance = false);
    }
  }

  Future<void> _openService() async {
    final url = AppConfigStore.instance.config?.onlineUrl.trim() ?? '';
    final target = Uri.tryParse(url);
    if (target == null || !await launchUrl(target)) {
      showToast(url.isEmpty ? '客服信息暂未配置' : '客服链接打开失败', type: ToastType.error);
    }
  }

  void _runAuthenticated(VoidCallback action) {
    if (Get.find<UserStore>().isLoggedIn) {
      action();
      return;
    }
    unawaited(_showLoginPrompt());
  }

  Future<void> _showLoginPrompt() async {
    if (_showingLoginPrompt || !mounted) return;
    _showingLoginPrompt = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => LegacyMessageDialog(
        title: '提示',
        message: '您还未登录，请先登录!',
        confirmLabel: '去登录',
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          Get.toNamed<void>(AppRoutes.login);
        },
      ),
    );
    _showingLoginPrompt = false;
  }

  Future<void> _launchGame(GameItem game) async {
    if (!Get.find<UserStore>().isLoggedIn) {
      await _showLoginPrompt();
      return;
    }
    if (game.id <= 0 || _launchingGameId != null) return;
    setState(() => _launchingGameId = game.id);
    try {
      final launch = await GameApi.enterGame(gameId: game.id);
      if (mounted) await Get.to<void>(() => GameDetailPage(launch: launch));
    } catch (_) {
      // GameApi shows the backend failure message.
    } finally {
      if (mounted) setState(() => _launchingGameId = null);
    }
  }

  Future<void> _openWithdraw() async {
    // The legacy controller waited for `paymentDrawNeed` before navigation,
    // which leaves the tap seemingly unresponsive on a slow line. The
    // destination owns that request and shows its loading state immediately.
    await Get.toNamed<dynamic>(AppRoutes.gameWithdraw);
    if (mounted) unawaited(_refreshBalance());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoggedIn = Get.find<UserStore>().isLoggedIn;
    if (isLoggedIn && _loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (isLoggedIn && _error != null && _categories.isEmpty) {
      return SafeArea(
        child: Center(
          child: TextButton(
            onPressed: () => unawaited(_load()),
            child: const Text('加载失败，点击重试'),
          ),
        ),
      );
    }
    final selected = _categories.isEmpty
        ? null
        : _categories[_selectedCategory.clamp(0, _categories.length - 1)];
    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: <Widget>[
            _GameAppBar(onService: () => unawaited(_openService())),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: isLoggedIn ? _load : _loadPublicContent,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  children: <Widget>[
                    if (_banners.isNotEmpty)
                      HomeBannerCarousel(items: _banners)
                    else
                      Image.asset(
                        'assets/images/bg_game_banner.png',
                        height: 200,
                        fit: BoxFit.fill,
                      ),
                    const SizedBox(height: 10),
                    _BalancePanel(
                      balance: _balance,
                      refreshing: _refreshingBalance,
                      onRefresh: () =>
                          _runAuthenticated(() => unawaited(_refreshBalance())),
                      onRecharge: () => _runAuthenticated(
                        () => Get.toNamed<void>(AppRoutes.gameRecharge),
                      ),
                      onWithdraw: () =>
                          _runAuthenticated(() => unawaited(_openWithdraw())),
                      onActivities: () => _runAuthenticated(
                        () => Get.toNamed<void>(AppRoutes.gameActivities),
                      ),
                      onService: () =>
                          _runAuthenticated(() => unawaited(_openService())),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 330,
                      child: _categories.isEmpty
                          ? isLoggedIn
                                ? const Center(
                                    child: Text(
                                      '暂无游戏',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                          : Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 55,
                                  child: ListView.separated(
                                    itemCount: _categories.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 4),
                                    itemBuilder: (context, index) =>
                                        _GameCategoryButton(
                                          category: _categories[index],
                                          selected: index == _selectedCategory,
                                          onTap: () => setState(
                                            () => _selectedCategory = index,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _GameGrid(
                                    games:
                                        selected?.games ?? const <GameItem>[],
                                    launchingGameId: _launchingGameId,
                                    onTap: _launchGame,
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
      ),
    );
  }
}

class _GameAppBar extends StatelessWidget {
  const _GameAppBar({required this.onService});
  final VoidCallback onService;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('game_app_bar'),
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
    ),
    child: Row(
      children: <Widget>[
        const SizedBox(width: 60),
        const Expanded(
          child: Center(
            child: Text(
              '游戏',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onService,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF6699),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/server_colorful.png',
                      width: 16,
                      height: 15,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '客服',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.balance,
    required this.refreshing,
    required this.onRefresh,
    required this.onRecharge,
    required this.onWithdraw,
    required this.onActivities,
    required this.onService,
  });
  final int balance;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onRecharge;
  final VoidCallback onWithdraw;
  final VoidCallback onActivities;
  final VoidCallback onService;
  @override
  Widget build(BuildContext context) => Container(
    height: 75,
    padding: const EdgeInsets.only(left: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 4),
      ],
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 13),
              Text(
                Get.find<UserStore>().user.value?.nickname ?? '请登录',
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  const Text('￥', style: TextStyle(fontSize: 12)),
                  Text(
                    (balance / 100).toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 24,
                    child: Center(
                      child: refreshing
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onRefresh,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: SvgPicture.asset(
                                  'assets/images/ic_refresh.svg',
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        for (final action in <(String, String)>[
          ('充值', 'assets/images/ic_game_recharge.svg'),
          ('提现', 'assets/images/ic_game_withdrawel.svg'),
          ('活动', 'assets/images/ic_game_active.svg'),
          ('客服', 'assets/images/ic_game_server.svg'),
        ])
          InkWell(
            onTap: switch (action.$1) {
              '客服' => onService,
              '活动' => onActivities,
              '充值' => onRecharge,
              '提现' => onWithdraw,
              _ => onService,
            },
            child: SizedBox(
              width: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(action.$2, width: 40, height: 40),
                  const SizedBox(height: 2),
                  Text(action.$1, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _GameCategoryButton extends StatelessWidget {
  const _GameCategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final GameCategory category;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SvgPicture.asset(
            selected
                ? 'assets/images/ic_game_category_sel.svg'
                : 'assets/images/ic_game_category_unsel.svg',
            width: 50,
            height: 54,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 27,
                child: LegacyNetworkImage(
                  url: category.iconUrl,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({
    required this.games,
    required this.launchingGameId,
    required this.onTap,
  });
  final List<GameItem> games;
  final int? launchingGameId;
  final ValueChanged<GameItem> onTap;
  @override
  Widget build(BuildContext context) => GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 138 / 114,
    ),
    itemCount: games.length,
    itemBuilder: (context, index) => InkWell(
      onTap: launchingGameId == null ? () => onTap(games[index]) : null,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          LegacyNetworkImage(
            url: games[index].thumbnailUrl,
            fit: BoxFit.contain,
            borderRadius: BorderRadius.circular(4),
          ),
          if (launchingGameId == games[index].id)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
