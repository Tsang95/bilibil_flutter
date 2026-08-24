import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
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
          _banners = const <BannerItem>[];
          _categories = const <GameCategory>[];
          _balance = 0;
          _error = null;
          _loading = false;
        });
      }
    });
    if (userStore.isLoggedIn) {
      unawaited(_load());
    } else {
      _loading = false;
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

  void _comingSoon() => showToast('该游戏功能正在重构中', type: ToastType.info);

  Future<void> _launchGame(GameItem game) async {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!Get.find<UserStore>().isLoggedIn) return const _GameLoginRequired();
    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _categories.isEmpty) {
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
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: <Widget>[
            _GameAppBar(onService: () => unawaited(_openService())),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
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
                      onRefresh: _refreshBalance,
                      onAction: _comingSoon,
                      onActivities: () =>
                          Get.toNamed<void>(AppRoutes.gameActivities),
                      onService: _openService,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 330,
                      child: _categories.isEmpty
                          ? const Center(
                              child: Text(
                                '暂无游戏',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
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

class _GameLoginRequired extends StatelessWidget {
  const _GameLoginRequired();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: TextButton(
          onPressed: () => Get.toNamed<void>('/login'),
          child: const Text(
            '登录后进入游戏大厅',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ),
    ),
  );
}

class _GameAppBar extends StatelessWidget {
  const _GameAppBar({required this.onService});
  final VoidCallback onService;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const Text('游戏', style: TextStyle(fontSize: 16)),
        Positioned(
          right: 10,
          child: InkWell(
            onTap: onService,
            borderRadius: BorderRadius.circular(20),
            child: Container(
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
      ],
    ),
  );
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.balance,
    required this.refreshing,
    required this.onRefresh,
    required this.onAction,
    required this.onActivities,
    required this.onService,
  });
  final int balance;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onAction;
  final VoidCallback onActivities;
  final Future<void> Function() onService;
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
                  IconButton(
                    onPressed: refreshing ? null : onRefresh,
                    icon: refreshing
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.refresh,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 24,
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
              '客服' => () => unawaited(onService()),
              '活动' => onActivities,
              _ => onAction,
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
