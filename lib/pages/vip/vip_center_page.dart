import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

enum VipType { movie, creator }

class VipCenterPage extends StatelessWidget {
  const VipCenterPage({super.key, this.initialType = VipType.movie});

  final VipType initialType;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: LegacyAppBar(
          title: initialType == VipType.creator ? '认证中心' : '会员中心',
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.recharge),
            child: const Text('前往充值', style: TextStyle(fontSize: 14)),
          ),
        ),
        body: _VipProducts(type: initialType),
      );
}

class _VipProducts extends StatefulWidget {
  const _VipProducts({required this.type});
  final VipType type;

  @override
  State<_VipProducts> createState() => _VipProductsState();
}

class _VipProductsState extends State<_VipProducts>
    with AutomaticKeepAliveClientMixin<_VipProducts> {
  List<VipProduct> _products = const <VipProduct>[];
  Object? _error;
  bool _loading = true;
  bool _submitting = false;
  int _selectedIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = widget.type == VipType.movie
          ? await UserApi.getMovieVipProducts(forceRefresh: forceRefresh)
          : await UserApi.getCreatorVipProducts(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _products = products;
          _selectedIndex = 0;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy() async {
    final product = _products.isEmpty ? null : _products[_selectedIndex];
    final store = Get.find<UserStore>();
    if (product == null || _submitting) return;
    final confirmed = await Get.dialog<bool>(
      LegacyMessageDialog(
        title: '提示',
        message:
            '确定花费${_number(product.price)}金币购买${product.name}吗？购买成功即可享受对应特权。',
        cancelLabel: '取消',
        onCancel: () => Get.back(result: false),
        onConfirm: () => Get.back(result: true),
      ),
    );
    if (confirmed != true || !mounted) return;

    if ((store.user.value?.goldBalance ?? 0) < product.price) {
      final recharge = await Get.dialog<bool>(
        LegacyMessageDialog(
          title: '提示',
          message: '余额不足，请前往充值',
          cancelLabel: '取消',
          confirmLabel: '确认',
          onCancel: () => Get.back(result: false),
          onConfirm: () => Get.back(result: true),
        ),
      );
      if (recharge == true) Get.toNamed<void>(AppRoutes.recharge);
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.type == VipType.movie) {
        await UserApi.buyMovieVip(productId: product.id);
      } else {
        await UserApi.buyCreatorVip(productId: product.id);
      }
      showToast('购买成功', type: ToastType.success);
      unawaited(_refreshUser(store));
    } catch (_) {
      // ApiClient provides the legacy failure toast.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshUser(UserStore store) async {
    try {
      store.user.value = await UserApi.getCurrentUser();
    } catch (_) {
      // A completed purchase remains successful if background refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _StateView(message: '加载失败', action: _load);
    if (_products.isEmpty) return const _StateView(message: '暂无会员套餐');
    final selected = _products[_selectedIndex.clamp(0, _products.length - 1)];
    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(forceRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
              children: <Widget>[
                Obx(
                  () => _VipInfo(
                    user: Get.find<UserStore>().user.value,
                    type: widget.type,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 115 / 90,
                  ),
                  itemBuilder: (context, index) => _ProductCard(
                    product: _products[index],
                    selected: index == _selectedIndex,
                    creator: widget.type == VipType.creator,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('专享权益', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                ..._benefits(selected).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 60,
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${selected.name}:${_number(selected.price)}元',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '原价：${_number(selected.oldPrice)}元',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 160,
                child: LegacyActionButton(
                  label: '确认支付',
                  onPressed: _submitting ? null : _buy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _benefits(VipProduct product) => widget.type == VipType.movie
      ? <String>[
          '1、VIP视频无限看',
          '2、评论次数+${product.commentLimit}',
          '3、私信次数+${product.privateMessageLimit}',
        ]
      : <String>[
          '可创作圈子：${product.categoryNames.join(' ')}',
          '发帖次数：+${product.postLimit}',
          '有效期：${product.days}天，博主认证时间到期后未续费将不在享有平台收益；',
          '进阶路线：赚够金币后，升级超级会员，发帖次数更多，赚的更多',
        ];
}

class _VipInfo extends StatelessWidget {
  const _VipInfo({required this.user, required this.type});
  final UserInfo? user;
  final VipType type;

  @override
  Widget build(BuildContext context) {
    final expires = type == VipType.movie
        ? user?.movieVipExpiresAt
        : user?.mediaVipExpiresAt;
    final isVip = type == VipType.movie
        ? user?.isVideoVip == true
        : user?.isCreatorVip == true;
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 110,
            child: Image(
              image: AssetImage('assets/images/bg_user_vip.png'),
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            width: 48,
            height: 48,
            child: _VipAvatar(user: user, showBadge: isVip),
          ),
          Positioned(
            top: 10,
            left: 68,
            right: 110,
            child: Text(
              user?.nickname.isNotEmpty == true ? user!.nickname : '请登录',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            top: 36,
            left: 68,
            right: 110,
            child: Text(
              '金币：${_number(user?.goldBalance ?? 0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Positioned(
            top: 64,
            left: 68,
            right: 8,
            child: Text(
              isVip
                  ? '到期时间：${expires?.toString() ?? ''}'
                  : type == VipType.movie
                      ? '您当前未开通VIP会员'
                      : '您当前未开通自媒体UP主',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _VipAvatar extends StatelessWidget {
  const _VipAvatar({required this.user, required this.showBadge});

  final UserInfo? user;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final level = (user?.movieVipLevel ?? 0).clamp(0, 5) + 1;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Positioned.fill(
          child: LegacyNetworkImage(
            url: user?.avatarUrl ?? '',
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        if (showBadge)
          Image.asset(
            'assets/images/v1/ic_vip_level$level.png',
            width: 37,
            height: 16,
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.creator,
    required this.onTap,
  });
  final VipProduct product;
  final bool selected;
  final bool creator;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                product.name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(
                      text: '￥',
                      style: TextStyle(color: AppColors.primary, fontSize: 11),
                    ),
                    TextSpan(
                      text: _number(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (creator)
                      const TextSpan(
                        text: '/月',
                        style:
                            TextStyle(color: AppColors.primary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Text(
                '原价${_number(product.oldPrice)}元',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StateView extends StatelessWidget {
  const _StateView({required this.message, this.action});
  final String message;
  final Future<void> Function()? action;
  @override
  Widget build(BuildContext context) => Center(
        child: action == null
            ? Text(message)
            : TextButton(onPressed: action, child: Text(message)),
      );
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
