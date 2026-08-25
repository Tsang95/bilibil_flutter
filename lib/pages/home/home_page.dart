import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/pages/active/active_page.dart';
import 'package:b_flutter/pages/home/home_landing_page.dart';
import 'package:b_flutter/pages/home/home_startup_controller.dart';
import 'package:b_flutter/pages/mine/mine_page.dart';
import 'package:b_flutter/pages/message/message_page.dart';
import 'package:b_flutter/pages/game/game_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final HomeStartupController _startupController = HomeStartupController();
  late final List<Widget> _pages;
  int _index = 0;
  DateTime? _lastBackPressedAt;
  bool _showTaskEntry = true;
  bool _showAdsEntry = true;

  @override
  void initState() {
    super.initState();
    _startupController.start();
    _pages = <Widget>[
      HomeLandingPage(
        onOpenMessage: () => _jumpTo(3),
        onOpenMine: () => _jumpTo(4),
      ),
      const ActivePage(),
      const GamePage(),
      const MessagePage(),
      const MinePage(),
    ];
  }

  void _jumpTo(int index) {
    if (_index == index) return;
    setState(() => _index = index);
    if (_pageController.hasClients) _pageController.jumpToPage(index);
  }

  void _openTaskCenter() {
    if (!Get.find<UserStore>().isLoggedIn) {
      Get.toNamed<void>(AppRoutes.login);
      return;
    }
    Get.toNamed<void>(AppRoutes.taskCenter);
  }

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;
    final now = DateTime.now();
    final previous = _lastBackPressedAt;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 2)) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        SystemNavigator.pop();
      }
      return;
    }
    _lastBackPressedAt = now;
    showToast('再按一次退出应用');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pages.length,
              itemBuilder: (context, index) =>
                  _KeepAlivePage(child: _pages[index]),
            ),
            if (_showAdsEntry)
              Positioned(
                left: 6,
                bottom: 12,
                child: _FloatingEntry(
                  imagePath: 'assets/images/ic_float_post_ads.png',
                  semanticLabel: '发布广告',
                  onClose: () => setState(() => _showAdsEntry = false),
                  onTap: () => showToast('广告发布模块正在重构', type: ToastType.info),
                ),
              ),
            if (_showTaskEntry)
              Positioned(
                right: 6,
                bottom: 12,
                child: _FloatingEntry(
                  imagePath: 'assets/images/v1/task_center_logo.png',
                  semanticLabel: '任务中心',
                  onClose: () => setState(() => _showTaskEntry = false),
                  onTap: _openTaskCenter,
                ),
              ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          final messageCount =
              Get.find<UserStore>().user.value?.totalInteractionMessages ?? 0;
          return BottomNavigationBar(
            currentIndex: _index,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.navigationUnselected,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            onTap: _jumpTo,
            items: <BottomNavigationBarItem>[
              _navigationItem('首页', 'home'),
              _navigationItem('动态', 'movie'),
              _navigationItem('游戏', 'game'),
              _navigationItem('消息', 'message', badgeCount: messageCount),
              _navigationItem('我的', 'mine'),
            ],
          );
        }),
      ),
    );
  }

  BottomNavigationBarItem _navigationItem(
    String label,
    String assetName, {
    int badgeCount = 0,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: _NavigationIcon(
        assetPath: 'assets/images/navi/ic_${assetName}_unsel.svg',
        badgeCount: badgeCount,
      ),
      activeIcon: _NavigationIcon(
        assetPath: 'assets/images/navi/ic_${assetName}_sel.svg',
        badgeCount: badgeCount,
      ),
    );
  }
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({required this.assetPath, required this.badgeCount});

  final String assetPath;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 25,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          SvgPicture.asset(assetPath, width: 24, height: 24),
          if (badgeCount > 0)
            Positioned(
              right: -1,
              top: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3.5,
                    vertical: 1,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingEntry extends StatelessWidget {
  const _FloatingEntry({
    required this.imagePath,
    required this.semanticLabel,
    required this.onClose,
    required this.onTap,
  });

  final String imagePath;
  final String semanticLabel;
  final VoidCallback onClose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: onClose,
          child: const Icon(
            Icons.cancel_outlined,
            color: Colors.black26,
            size: 18,
          ),
        ),
        Semantics(
          button: true,
          label: semanticLabel,
          child: GestureDetector(
            onTap: onTap,
            child: Image.asset(imagePath, width: 60, height: 58),
          ),
        ),
      ],
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
