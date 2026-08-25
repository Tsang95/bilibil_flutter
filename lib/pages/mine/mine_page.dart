import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/pages/mine/identity_card_page.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

/// The legacy account landing page.  Detail destinations are migrated in
/// their respective modules; this page owns only the account summary chrome.
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage>
    with AutomaticKeepAliveClientMixin<MinePage> {
  bool _refreshing = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    final store = Get.find<UserStore>();
    if (!store.isLoggedIn || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      store.user.value = await UserApi.getCurrentUser();
    } catch (_) {
      // ApiClient presents the legacy request error toast.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _requireLogin(VoidCallback action) {
    if (!Get.find<UserStore>().isLoggedIn) {
      Get.toNamed<void>(AppRoutes.login);
      return;
    }
    action();
  }

  void _notYetAvailable() => showToast('该功能正在重构中', type: ToastType.info);

  Future<void> _openConfiguredLink(
    String url, {
    required String unavailableMessage,
  }) async {
    final target = Uri.tryParse(url.trim());
    if (target == null || target.scheme.isEmpty) {
      showToast(unavailableMessage, type: ToastType.info);
      return;
    }
    if (!await launchUrl(target)) {
      showToast('链接打开失败', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userStore = Get.find<UserStore>();
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Obx(() {
          final user = userStore.user.value;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: <Widget>[
                const SizedBox(height: 20),
                _AccountHeader(
                  user: user,
                  onTap: () => _requireLogin(
                    () => Get.toNamed<dynamic>(AppRoutes.personalInfo),
                  ),
                ),
                const SizedBox(height: 20),
                _AccountStats(
                  user: user,
                  onTap: (index) => _requireLogin(
                    index == 0
                        ? () => Get.toNamed<dynamic>(AppRoutes.collect)
                        : index == 1
                        ? () => Get.toNamed<dynamic>(AppRoutes.buy)
                        : index == 2
                        ? () => Get.toNamed<dynamic>(AppRoutes.followList)
                        : index == 3
                        ? () => Get.toNamed<dynamic>(AppRoutes.myFans)
                        : () => Get.toNamed<dynamic>(AppRoutes.creatorCenter),
                  ),
                ),
                if (user == null) ...<Widget>[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _LoginButton(
                      onTap: () => Get.toNamed<void>(AppRoutes.login),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _MembershipCards(
                    onCertificationTap: () => _requireLogin(
                      () => Get.toNamed<void>(
                        AppRoutes.vipCenter,
                        arguments: VipType.creator,
                      ),
                    ),
                    onVipTap: () => _requireLogin(
                      () => Get.toNamed<void>(AppRoutes.vipCenter),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _ServiceSection(
                    title: '推荐服务',
                    actions: <_MineAction>[
                      _MineAction(
                        '我的钱包',
                        'assets/images/v1/ic_wallet.svg',
                        () => _requireLogin(
                          () => Get.toNamed<void>(AppRoutes.wallet),
                        ),
                      ),
                      _MineAction(
                        '历史记录',
                        'assets/images/v1/ic_history.svg',
                        () => _requireLogin(
                          () => Get.toNamed<dynamic>(AppRoutes.lookHistory),
                        ),
                      ),
                      _MineAction(
                        '数据中心',
                        'assets/images/v1/ic_mine_data_center.svg',
                        _notYetAvailable,
                      ),
                      _MineAction(
                        '推广中心',
                        'assets/images/v1/ic_invite.svg',
                        () => _requireLogin(
                          () => Get.toNamed<void>(AppRoutes.invite),
                        ),
                      ),
                      _MineAction(
                        '创作中心',
                        'assets/images/v1/ic_follow.svg',
                        () => _requireLogin(
                          () => Get.toNamed<void>(AppRoutes.creationCenter),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _PromotionCard(
                  tag: 'UP',
                  title: '发布你的第一个视频',
                  subtitle: '赢活动奖励',
                  button: '有奖发布',
                  image: 'assets/images/v1/ic_create_post_upload.svg',
                  onTap: () => _requireLogin(
                    () => Get.toNamed<void>(AppRoutes.creatorCenter),
                  ),
                ),
                _PromotionCard(
                  tag: 'AD',
                  title: '一键自助发布广告引流',
                  subtitle: '黄金广告位置自由选择',
                  button: '投放广告',
                  image: 'assets/images/ic_create_ads.svg',
                  onTap: () => _requireLogin(_notYetAvailable),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _ServiceSection(
                    title: '推荐服务',
                    actions: <_MineAction>[
                      _MineAction(
                        '任务中心',
                        'assets/images/v1/ic_task_center.svg',
                        () => _requireLogin(
                          () => Get.toNamed<dynamic>(AppRoutes.taskCenter),
                        ),
                      ),
                      _MineAction(
                        '身份卡',
                        'assets/images/v1/ic_idcard.svg',
                        () => _requireLogin(
                          () => Get.dialog<void>(const IdentityCardDialog()),
                        ),
                      ),
                      _MineAction(
                        '谷歌验证码',
                        'assets/images/v1/ic_google_verify.svg',
                        () => _requireLogin(
                          () => Get.toNamed<dynamic>(AppRoutes.googleVerify),
                        ),
                      ),
                      _MineAction(
                        '支付密码',
                        'assets/images/v1/ic_pay_password.svg',
                        () => _requireLogin(
                          () => Get.toNamed<dynamic>(AppRoutes.setPayPassword),
                        ),
                      ),
                      _MineAction(
                        '修改密码',
                        'assets/images/v1/ic_password.svg',
                        () => _requireLogin(
                          () => Get.toNamed<dynamic>(AppRoutes.changePassword),
                        ),
                      ),
                      _MineAction(
                        '联系客服',
                        'assets/images/v1/ic_server.svg',
                        () => _openConfiguredLink(
                          AppConfigStore.instance.config?.onlineUrl ?? '',
                          unavailableMessage: '客服信息暂未配置',
                        ),
                      ),
                      _MineAction(
                        '帮助中心',
                        'assets/images/v1/ic_help.svg',
                        () => Get.toNamed<dynamic>(AppRoutes.helpCenter),
                      ),
                      _MineAction(
                        '用户建议',
                        'assets/images/v1/ic_feedback.svg',
                        () => Get.toNamed<void>(AppRoutes.userFeedback),
                      ),
                      _MineAction(
                        '商务合作',
                        'assets/images/v1/ic_telegram.svg',
                        () => _openConfiguredLink(
                          AppConfigStore.instance.config?.businessContact ?? '',
                          unavailableMessage: '商务合作信息暂未配置',
                        ),
                      ),
                      _MineAction(
                        '官方交流群',
                        'assets/images/v1/ic_telegram_group.svg',
                        () => _openConfiguredLink(
                          AppConfigStore.instance.config?.telegramGroup ?? '',
                          unavailableMessage: '官方群信息暂未配置',
                        ),
                      ),
                    ],
                  ),
                ),
                if (user != null) ...<Widget>[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: OutlinedButton(
                      onPressed: () => Get.toNamed<void>(AppRoutes.login),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.textSecondary),
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('切换账号'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user, required this.onTap});

  final UserInfo? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = user != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: 48,
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 48,
                child: isLoggedIn && user!.avatarUrl.isNotEmpty
                    ? LegacyNetworkImage(
                        url: user!.avatarUrl,
                        borderRadius: BorderRadius.circular(24),
                      )
                    : SvgPicture.asset(
                        'assets/images/user_header_placeholder.svg',
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          isLoggedIn ? user!.nickname : '请登录',
                          style: const TextStyle(fontSize: 15),
                        ),
                        if (isLoggedIn) ...<Widget>[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: '${user!.id}'),
                              );
                              showToast('复制成功', type: ToastType.success);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'ID:${user!.id}  ⧉',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        children: <InlineSpan>[
                          const TextSpan(text: '金币：'),
                          TextSpan(
                            text: _formatNumber(user?.goldBalance ?? 0),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const TextSpan(text: '                    硬币：'),
                          TextSpan(
                            text: '${user?.coinCount ?? 0}',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoggedIn)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('个人空间', style: TextStyle(fontSize: 14)),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountStats extends StatelessWidget {
  const _AccountStats({required this.user, required this.onTap});

  final UserInfo? user;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final values = <(String, int)>[
      ('我的收藏', user?.collectCount ?? 0),
      ('我的购买', user?.buyCount ?? 0),
      ('我的关注', user?.followCount ?? 0),
      ('我的粉丝', user?.fansCount ?? 0),
      ('创作次数', user?.mediaPostCount ?? 0),
    ];
    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: index == values.length - 1
                        ? null
                        : const Border(
                            right: BorderSide(
                              width: .5,
                              color: AppColors.divider,
                            ),
                          ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${values[index].$2}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        values[index].$1,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '登录解锁更多权限',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    ),
  );
}

class _MembershipCards extends StatelessWidget {
  const _MembershipCards({
    required this.onCertificationTap,
    required this.onVipTap,
  });
  final VoidCallback onCertificationTap;
  final VoidCallback onVipTap;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _MembershipCard(
          label: '认证中心',
          image: 'assets/images/bg_user_work.png',
          onTap: onCertificationTap,
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: _MembershipCard(
          label: '会员中心',
          image: 'assets/images/bg_user_vip.png',
          onTap: onVipTap,
        ),
      ),
    ],
  );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.label,
    required this.image,
    required this.onTap,
  });
  final String label;
  final String image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFAAA9), Color(0xFFFF5D90)],
        ),
        image: DecorationImage(
          image: AssetImage(image),
          alignment: Alignment.centerRight,
          fit: BoxFit.fitHeight,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    ),
  );
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.image,
    required this.onTap,
  });
  final String tag;
  final String title;
  final String subtitle;
  final String button;
  final String image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 65,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(image, width: 14, height: 14),
                const SizedBox(width: 5),
                Text(
                  button,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({required this.title, required this.actions});
  final String title;
  final List<_MineAction> actions;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 20),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 20,
          childAspectRatio: 71 / 55,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return InkWell(
            onTap: action.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(action.asset, width: 24, height: 24),
                const SizedBox(height: 5),
                Text(
                  action.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _MineAction {
  const _MineAction(this.name, this.asset, this.onTap);
  final String name;
  final String asset;
  final VoidCallback onTap;
}

String _formatNumber(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();
