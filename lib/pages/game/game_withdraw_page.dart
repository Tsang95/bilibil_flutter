import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

class GameWithdrawPage extends StatefulWidget {
  const GameWithdrawPage({super.key});

  @override
  State<GameWithdrawPage> createState() => _GameWithdrawPageState();
}

class _GameWithdrawPageState extends State<GameWithdrawPage> {
  final _amountController = TextEditingController();
  GameWithdrawNeed? _need;
  int _balanceInCents = 0;
  Object? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _need = Get.arguments is GameWithdrawNeed
        ? Get.arguments as GameWithdrawNeed
        : null;
    unawaited(_load());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        _need == null ? GameApi.getWithdrawNeed() : Future.value(_need!),
        GameApi.getBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _need = values[0] as GameWithdrawNeed;
        _balanceInCents = values[1] as int;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bindBank() async {
    // AppPages registers routes as GetPage<dynamic>; asking Get to create a
    // Route<GameBankBinding?> makes Navigator cast the generated route and
    // crashes before the page is shown. Validate the returned route value
    // after navigation instead.
    final result = await Get.toNamed<dynamic>(AppRoutes.gameBindBank);
    final binding = result is GameBankBinding ? result : null;
    if (binding == null || !mounted) return;
    setState(() {
      final need = _need;
      if (need != null) {
        _need = GameWithdrawNeed(
          amountInCents: need.amountInCents,
          requiredAmountInCents: need.requiredAmountInCents,
          bankBinding: binding,
        );
      }
    });
  }

  void _withdrawAll() =>
      _amountController.text = (_balanceInCents / 100).toStringAsFixed(2);

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      showToast('请输入正确的提现金额', type: ToastType.info);
      return;
    }
    if ((amount * 100).round() > _balanceInCents) {
      showToast('余额不足', type: ToastType.info);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await GameApi.withdraw(amount: amount);
      if (!mounted) return;
      showToast('提交成功，请等待审核', type: ToastType.success);
      await Get.toNamed<void>(AppRoutes.gameWithdrawRecords);
      if (mounted) unawaited(_load());
    } catch (_) {
      // GameApi has already shown the backend error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final need = _need;
    return Scaffold(
      appBar: LegacyAppBar(
        title: '提现',
        trailing: TextButton(
          onPressed: () => Get.toNamed<void>(AppRoutes.gameWithdrawRecords),
          child: const Text('提现记录', style: TextStyle(fontSize: 12)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || need == null
          ? Center(
              child: TextButton(
                onPressed: () => unawaited(_load()),
                child: const Text('加载失败，点击重试'),
              ),
            )
          : !need.isBankBound
          ? _UnboundBankView(onBind: () => unawaited(_bindBank()))
          : ListView(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
              children: <Widget>[
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Text(
                        '可用余额：',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        (_balanceInCents / 100).toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _WithdrawFieldLabel('提现金额（元）'),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.centerRight,
                  children: <Widget>[
                    LegacyTextField(
                      controller: _amountController,
                      hintText: '请输入金额',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextButton(
                      onPressed: _withdrawAll,
                      child: const Text('全部提现', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _WithdrawFieldLabel('提现方式'),
                const SizedBox(height: 10),
                Container(
                  width: 110,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/ic_bank.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '银行卡',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _WithdrawFieldLabel('提款账号'),
                const SizedBox(height: 10),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          need.bankBinding!.bankName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        need.bankBinding!.cardNumber,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                LegacyActionButton(
                  label: _submitting ? '提交中...' : '确认',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
    );
  }
}

class _UnboundBankView extends StatelessWidget {
  const _UnboundBankView({required this.onBind});
  final VoidCallback onBind;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      children: <Widget>[
        const SizedBox(height: 20),
        Image.asset(
          'assets/images/empty_bind_bank_card.png',
          width: 200,
          height: 200,
        ),
        const Text(
          '暂未绑定银行卡',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        LegacyActionButton(label: '去绑定', onPressed: onBind),
      ],
    ),
  );
}

class _WithdrawFieldLabel extends StatelessWidget {
  const _WithdrawFieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14));
}
