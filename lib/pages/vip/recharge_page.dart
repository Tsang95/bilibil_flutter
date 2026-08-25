import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/configured_link.dart';
import 'package:b_flutter/utils/toast.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});
  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  List<RechargeProduct> _products = const <RechargeProduct>[];
  List<RechargeChannel> _channels = const <RechargeChannel>[];
  int _productIndex = 0;
  int _channelIndex = 0;
  Object? _error;
  bool _loading = true;
  bool _loadingChannels = false;
  bool _submitting = false;
  int _channelVersion = 0;

  RechargeProduct? get _product => _products.isEmpty
      ? null
      : _products[_productIndex.clamp(0, _products.length - 1)];
  RechargeChannel? get _channel => _channels.isEmpty
      ? null
      : _channels[_channelIndex.clamp(0, _channels.length - 1)];

  @override
  void initState() {
    super.initState();
    unawaited(_loadProducts());
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await UserApi.getRechargeProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _productIndex = products.indexWhere((item) => item.isSelected);
        if (_productIndex < 0) _productIndex = 0;
      });
      if (_product != null) await _loadChannels();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadChannels() async {
    final product = _product;
    if (product == null) return;
    final version = ++_channelVersion;
    setState(() {
      _loadingChannels = true;
      _channels = const <RechargeChannel>[];
      _channelIndex = 0;
    });
    try {
      final channels = await UserApi.getRechargeChannels(amount: product.price);
      if (mounted && version == _channelVersion) {
        setState(() => _channels = channels);
      }
    } catch (error) {
      if (mounted && version == _channelVersion) setState(() => _error = error);
    } finally {
      if (mounted && version == _channelVersion) {
        setState(() => _loadingChannels = false);
      }
    }
  }

  Future<void> _pay() async {
    final product = _product;
    final channel = _channel;
    if (product == null || channel == null || _submitting) {
      showToast('请选择充值金额和渠道', type: ToastType.info);
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await UserApi.createRechargeOrder(
        productId: product.id,
        channelId: channel.id,
      );
      final uri = Uri.tryParse(order.url);
      if (uri == null ||
          uri.scheme.isEmpty ||
          !await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        showToast('支付链接打开失败', type: ToastType.error);
      }
    } catch (_) {
      // ApiClient reports the request failure.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openCustomerService() {
    unawaited(
      openConfiguredLink(
        AppConfigStore.instance.config?.onlineUrl ?? '',
        unavailableMessage: '客服信息暂未配置',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: LegacyAppBar(
      title: '充值',
      trailing: TextButton(
        onPressed: () => Get.toNamed<void>(AppRoutes.rechargeHistory),
        child: const Text('充值记录', style: TextStyle(fontSize: 14)),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _products.isEmpty
        ? Center(
            child: TextButton(
              onPressed: _loadProducts,
              child: const Text('加载失败，点击重试'),
            ),
          )
        : Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadProducts,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 30),
                    children: <Widget>[
                      _BalanceBanner(
                        amount:
                            Get.find<UserStore>().user.value?.goldBalance ?? 0,
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 115 / 90,
                            ),
                        itemBuilder: (context, index) => _RechargeProductCard(
                          product: _products[index],
                          selected: index == _productIndex,
                          onTap: () {
                            if (_productIndex == index) return;
                            setState(() => _productIndex = index);
                            unawaited(_loadChannels());
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('选择充值渠道', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 10),
                      if (_loadingChannels)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _channels.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 5,
                                childAspectRatio: 100 / 60,
                              ),
                          itemBuilder: (context, index) => _RechargeChannelCard(
                            channel: _channels[index],
                            selected: index == _channelIndex,
                            showRecommended: index == 0,
                            onTap: () => setState(() => _channelIndex = index),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        '选择渠道后，请耐心等待一会儿！！不要有别的操作；',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          children: <InlineSpan>[
                            const TextSpan(text: '充值后90秒内到账。充值不到账？'),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: InkWell(
                                onTap: _openCustomerService,
                                child: const Text(
                                  '点我联系客服',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '客服不在线？请点击订单不到账反馈，24小时内处理。',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Get.toNamed<void>(AppRoutes.vipCenter),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('前往会员中心购买会员'),
                      ),
                    ],
                  ),
                ),
              ),
              _RechargeFooter(
                product: _product,
                submitting: _submitting,
                onPay: _pay,
              ),
            ],
          ),
  );
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner({required this.amount});
  final double amount;
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    color: AppColors.primary,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text(
          '可用余额：',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Text(
          amount.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RechargeProductCard extends StatelessWidget {
  const _RechargeProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });
  final RechargeProduct product;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${product.goldCoin}金币',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            '￥${_money(product.price)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (product.additional.isNotEmpty)
            Text(
              product.additional,
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
        ],
      ),
    ),
  );
}

class _RechargeChannelCard extends StatelessWidget {
  const _RechargeChannelCard({
    required this.channel,
    required this.selected,
    required this.showRecommended,
    required this.onTap,
  });
  final RechargeChannel channel;
  final bool selected;
  final bool showRecommended;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final asset = channel.type == 1
        ? 'assets/images/alipay_circle.png'
        : channel.type == 0
        ? 'assets/images/wechat_pay.png'
        : 'assets/images/v1/ic_usdt.png';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(asset, width: 24, height: 24),
                const SizedBox(height: 4),
                Text(channel.name, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          if (showRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/images/barrage_recharge.png',
                width: 30,
                height: 30,
              ),
            ),
        ],
      ),
    );
  }
}

class _RechargeFooter extends StatelessWidget {
  const _RechargeFooter({
    required this.product,
    required this.submitting,
    required this.onPay,
  });
  final RechargeProduct? product;
  final bool submitting;
  final VoidCallback onPay;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${product?.goldCoin ?? 0}金币：${_money(product?.price ?? 0)}元',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 160,
            child: LegacyActionButton(
              label: '确认支付',
              onPressed: submitting ? null : onPay,
            ),
          ),
        ],
      ),
    ),
  );
}

String _money(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
