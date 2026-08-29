import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/configured_link.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final ScrollController _scrollController = ScrollController();
  List<WalletChangeRecord> _items = const <WalletChangeRecord>[];
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore || (!refresh && (!_hasMore || _loading))) return;
    final page = refresh ? 1 : _page + 1;
    setState(() {
      if (refresh) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await UserApi.getWalletChanges(
        page: page,
        forceRefresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _items = refresh
            ? result.items
            : <WalletChangeRecord>[..._items, ...result.items];
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '钱包'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: () => _load(refresh: true),
                      child: const Text('加载失败，点击重试'),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _load(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _items.length + 3,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(10),
                            child: _WalletSummary(),
                          );
                        }
                        if (index == 1) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Text('钱包日志', style: TextStyle(fontSize: 14)),
                          );
                        }
                        if (index == _items.length + 2) {
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (!_hasMore && _items.isNotEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  '没有更多了',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }
                          if (_items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(36),
                              child: Center(child: Text('暂无数据')),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return _WalletRecord(
                          record: _items[index - 2],
                          onRechargeFeedback: () => unawaited(
                            openConfiguredLink(
                              AppConfigStore.instance.config?.onlineUrl ?? '',
                              unavailableMessage: '客服信息暂未配置',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary();
  @override
  Widget build(BuildContext context) => Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Obx(() {
          final user = Get.find<UserStore>().user.value;
          return Column(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Balance(
                          label: '可用余额', value: user?.goldBalance ?? 0),
                    ),
                    Expanded(
                      child: _Balance(
                        label: '冻结余额',
                        value: user?.blockedBalance ?? 0,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _WalletButton(
                      asset: 'assets/images/ic_wallet_recharge.svg',
                      label: '充值',
                      inverted: true,
                      onTap: () => Get.toNamed<void>(AppRoutes.recharge),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _WalletButton(
                      asset: 'assets/images/ic_wallet_withdraw.svg',
                      label: '提现',
                      inverted: false,
                      onTap: () => Get.toNamed<void>(AppRoutes.withdraw),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      );
}

class _Balance extends StatelessWidget {
  const _Balance({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.asset,
    required this.label,
    required this.inverted,
    required this.onTap,
  });
  final String asset;
  final String label;
  final bool inverted;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: SvgPicture.asset(
            asset,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              inverted ? AppColors.textPrimary : Colors.white,
              BlendMode.srcIn,
            ),
          ),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: inverted ? AppColors.textPrimary : Colors.white,
            backgroundColor: inverted ? Colors.white : null,
            side: BorderSide(color: inverted ? Colors.white : Colors.white),
            shape: const StadiumBorder(),
          ),
        ),
      );
}

class _WalletRecord extends StatelessWidget {
  const _WalletRecord({required this.record, required this.onRechargeFeedback});
  final WalletChangeRecord record;
  final VoidCallback onRechargeFeedback;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${record.title}：',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${record.amount > 0 ? '+' : ''}${record.amount}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Text('时间：', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    record.createdAt,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('备注', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    record.content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRechargeFeedback,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.only(top: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '充值反馈',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
