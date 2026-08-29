import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/utils/toast.dart';

class GameBindBankPage extends StatefulWidget {
  const GameBindBankPage({super.key});

  @override
  State<GameBindBankPage> createState() => _GameBindBankPageState();
}

class _GameBindBankPageState extends State<GameBindBankPage> {
  final _accountNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  List<GameBank> _banks = const <GameBank>[];
  GameBank? _selectedBank;
  Object? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBanks());
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banks = await GameApi.getBanks();
      if (mounted) setState(() => _banks = banks);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseBank() async {
    if (_loading) return;
    if (_error != null && _banks.isEmpty) {
      await _loadBanks();
      return;
    }
    final selected = await showModalBottomSheet<GameBank>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 360,
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '请选择银行',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: _banks.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无可用银行',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _banks.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (_, index) => ListTile(
                          title: Text(
                            _banks[index].name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () =>
                              Navigator.of(sheetContext).pop(_banks[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _selectedBank = selected);
  }

  Future<void> _submit() async {
    final accountName = _accountNameController.text.trim();
    final cardNumber = _cardNumberController.text.trim();
    if (accountName.isEmpty) {
      showToast('请输入开户名', type: ToastType.info);
      return;
    }
    if (cardNumber.isEmpty) {
      showToast('请输入银行卡号', type: ToastType.info);
      return;
    }
    final bank = _selectedBank;
    if (bank == null) {
      showToast('请选择开户银行', type: ToastType.info);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final binding = await GameApi.bindBank(
        accountName: accountName,
        cardNumber: cardNumber,
        bank: bank,
      );
      if (!mounted) return;
      showToast('绑定成功', type: ToastType.success);
      Get.back<GameBankBinding>(
        result: binding.isBound
            ? binding
            : GameBankBinding(
                isBound: true,
                bankName:
                    binding.bankName.isEmpty ? bank.name : binding.bankName,
                cardNumber: binding.cardNumber.isEmpty
                    ? cardNumber
                    : binding.cardNumber,
              ),
      );
    } catch (_) {
      // GameApi has already shown the backend error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '绑定'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _banks.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: () => unawaited(_loadBanks()),
                      child: const Text('加载失败，点击重试'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
                    children: <Widget>[
                      const _FieldLabel('姓名（银行卡开户名）'),
                      const SizedBox(height: 10),
                      LegacyTextField(
                        controller: _accountNameController,
                        hintText: '请输入开户名',
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('银行卡号'),
                      const SizedBox(height: 10),
                      LegacyTextField(
                        controller: _cardNumberController,
                        hintText: '请输入银行卡号',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('开户银行'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () => unawaited(_chooseBank()),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _selectedBank?.name ?? '请选择银行',
                                      style: TextStyle(
                                        color: _selectedBank == null
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14));
}
