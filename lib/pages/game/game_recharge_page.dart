import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

class GameRechargePage extends StatefulWidget {
  const GameRechargePage({super.key});

  @override
  State<GameRechargePage> createState() => _GameRechargePageState();
}

class _GameRechargePageState extends State<GameRechargePage> {
  List<GameRechargeCategory> _categories = const <GameRechargeCategory>[];
  List<GamePaymentChannel> _channels = const <GamePaymentChannel>[];
  Object? _error;
  bool _loading = true;
  bool _loadingChannels = false;
  bool _submitting = false;
  int _channelRequest = 0;
  int _categoryIndex = 0;
  int _channelIndex = 0;
  int _amountIndex = 0;

  GamePaymentChannel? get _selectedChannel => _channels.isEmpty
      ? null
      : _channels[_channelIndex.clamp(0, _channels.length - 1)];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    _channelRequest++;
    setState(() {
      _loading = true;
      _loadingChannels = false;
      _error = null;
    });
    try {
      final categories = await GameApi.getRechargeCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryIndex = 0;
        _channels = const <GamePaymentChannel>[];
      });
      if (categories.isNotEmpty) await _loadChannels(categories.first.id);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadChannels(int categoryId) async {
    final request = ++_channelRequest;
    setState(() {
      _loadingChannels = true;
      _error = null;
    });
    try {
      final channels = await GameApi.getPaymentChannels(categoryId: categoryId);
      if (!mounted || request != _channelRequest) return;
      setState(() {
        _channels = channels;
        _channelIndex = 0;
        _amountIndex = 0;
      });
    } catch (error) {
      if (mounted && request == _channelRequest) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && request == _channelRequest) {
        setState(() => _loadingChannels = false);
      }
    }
  }

  Future<void> _selectCategory(int index) async {
    if (_loading || index == _categoryIndex) return;
    setState(() {
      _categoryIndex = index;
      _channels = const <GamePaymentChannel>[];
      _channelIndex = 0;
      _amountIndex = 0;
      _error = null;
    });
    await _loadChannels(_categories[index].id);
  }

  Future<void> _recharge() async {
    final channel = _selectedChannel;
    if (_submitting || channel == null || channel.quickAmounts.isEmpty) {
      showToast('请选择充值方式和金额', type: ToastType.info);
      return;
    }
    final amount = channel
        .quickAmounts[_amountIndex.clamp(0, channel.quickAmounts.length - 1)];
    setState(() => _submitting = true);
    try {
      final launch = await GameApi.createRecharge(
        channelId: channel.id,
        amount: amount,
      );
      final uri = Uri.tryParse(launch.url);
      if (uri == null || !await launchUrl(uri)) {
        showToast('支付链接打开失败', type: ToastType.error);
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PaymentResultButton(
                label: '支付完成',
                color: Colors.white,
                textColor: AppColors.textPrimary,
                onTap: () {
                  Navigator.of(context).pop();
                  Get.toNamed<void>(AppRoutes.gameRechargeRecords);
                },
              ),
              const SizedBox(height: 10),
              _PaymentResultButton(
                label: '取消支付',
                color: AppColors.textPrimary,
                textColor: Colors.white,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      // ApiClient has already displayed the backend error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: LegacyAppBar(
      title: '充值',
      trailing: TextButton(
        onPressed: () => Get.toNamed<void>(AppRoutes.gameRechargeRecords),
        child: const Text('充值记录', style: TextStyle(fontSize: 12)),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _categories.isEmpty
        ? Center(
            child: TextButton(
              onPressed: () => unawaited(_loadCategories()),
              child: const Text('加载失败，点击重试'),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadCategories,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
              children: <Widget>[
                const Text('支付方式', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                _CategoryGrid(
                  categories: _categories,
                  selectedIndex: _categoryIndex,
                  onTap: (index) => unawaited(_selectCategory(index)),
                ),
                const SizedBox(height: 20),
                if (_loadingChannels)
                  const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _channels.isEmpty)
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: TextButton(
                        onPressed: _categories.isEmpty
                            ? null
                            : () => unawaited(
                                _loadChannels(_categories[_categoryIndex].id),
                              ),
                        child: const Text('支付通道加载失败，点击重试'),
                      ),
                    ),
                  )
                else ...<Widget>[
                  _ChannelGrid(
                    channels: _channels,
                    selectedIndex: _channelIndex,
                    onTap: (index) => setState(() {
                      _channelIndex = index;
                      _amountIndex = 0;
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text('充值金额', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  _AmountGrid(
                    amounts: _selectedChannel?.quickAmounts ?? const <String>[],
                    selectedIndex: _amountIndex,
                    onTap: (index) => setState(() => _amountIndex = index),
                  ),
                  const SizedBox(height: 20),
                  LegacyActionButton(
                    label: _submitting ? '正在跳转支付…' : '立即充值',
                    onPressed: _submitting ? null : _recharge,
                  ),
                ],
              ],
            ),
          ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<GameRechargeCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 80 / 72,
    ),
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final selected = index == selectedIndex;
      final category = categories[index];
      return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: LegacyNetworkImage(url: category.thumbnailUrl),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChannelGrid extends StatelessWidget {
  const _ChannelGrid({
    required this.channels,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<GamePaymentChannel> channels;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 172 / 60,
    ),
    itemCount: channels.length,
    itemBuilder: (context, index) {
      final selected = index == selectedIndex;
      return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                channels[index].name,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AmountGrid extends StatelessWidget {
  const _AmountGrid({
    required this.amounts,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> amounts;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    itemCount: amounts.length,
    itemBuilder: (context, index) {
      final selected = index == selectedIndex;
      return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '￥',
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: amounts[index],
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${amounts[index]}金币',
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PaymentResultButton extends StatelessWidget {
  const _PaymentResultButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 40,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
        ),
      ),
    ),
  );
}
