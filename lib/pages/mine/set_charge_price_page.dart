import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class SetChargePricePage extends StatefulWidget {
  const SetChargePricePage({super.key});

  @override
  State<SetChargePricePage> createState() => _SetChargePricePageState();
}

class _SetChargePricePageState extends State<SetChargePricePage> {
  final _month = TextEditingController();
  final _quarter = TextEditingController();
  final _year = TextEditingController();
  bool _submitting = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _month.dispose();
    _quarter.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final price = await UserApi.getChargePrice();
      if (!mounted) return;
      setState(() {
        _error = null;
        _month.text = '${price.month}';
        _quarter.text = '${price.quarter}';
        _year.text = '${price.year}';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final month = int.tryParse(_month.text);
    final quarter = int.tryParse(_quarter.text);
    final year = int.tryParse(_year.text);
    if (month == null) {
      showToast('请设置月卡价格', type: ToastType.error);
      return;
    }
    if (quarter == null) {
      showToast('请设置季卡价格', type: ToastType.error);
      return;
    }
    if (year == null) {
      showToast('请设置年卡价格', type: ToastType.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => UserApi.updateChargePrice(
          month: month,
          quarter: quarter,
          year: year,
        ),
        loadingMessage: '提交中...',
        successMessage: '设置成功',
        fallbackErrorMessage: '设置失败，请稍后重试',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // SubmissionFeedback presents the request failure state.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '设置充电计划'),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: <Widget>[
              const SizedBox(height: 20),
              const Text('请设置充电套餐价格', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              _PriceField(label: '月卡', controller: _month),
              _PriceField(label: '季卡', controller: _quarter),
              _PriceField(label: '半年卡', controller: _year),
              if (_error != null)
                TextButton(onPressed: _load, child: const Text('加载失败，点击重试')),
              const SizedBox(height: 10),
              LegacyActionButton(
                label: '保存设置',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      );
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              decoration: const InputDecoration(
                hintText: '请输入套餐价格',
                suffixText: '金币',
                suffixStyle:
                    TextStyle(fontSize: 14, color: AppColors.textPrimary),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
        ],
      );
}
