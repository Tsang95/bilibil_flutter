import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/utils/toast.dart';

class SetPayPasswordPage extends StatefulWidget {
  const SetPayPasswordPage({super.key});

  @override
  State<SetPayPasswordPage> createState() => _SetPayPasswordPageState();
}

class _SetPayPasswordPageState extends State<SetPayPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (password.isEmpty) {
      showToast('请输入6位数字支付密码', type: ToastType.error);
      return;
    }
    if (confirmPassword.isEmpty) {
      showToast('请再次输入支付密码', type: ToastType.error);
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await UserApi.setPayPassword(
        password: password,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      showToast('设置成功', type: ToastType.success);
      Get.back<void>();
    } catch (_) {
      // UserApi presents the legacy backend error toast.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openService() async {
    final url = AppConfigStore.instance.config?.onlineUrl.trim() ?? '';
    if (url.isEmpty) {
      showToast('客服信息暂未配置', type: ToastType.info);
      return;
    }
    final target = Uri.tryParse(url);
    if (target == null || !await launchUrl(target)) {
      showToast('客服链接打开失败', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '设置支付密码'),
    body: dismissKeyboardWrapper(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
        children: <Widget>[
          const LegacyFieldLabel('支付密码'),
          const SizedBox(height: 10),
          LegacyTextField(
            controller: _passwordController,
            hintText: '请输入6位数字支付密码',
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            maxLength: 6,
          ),
          const SizedBox(height: 20),
          const LegacyFieldLabel('确认支付密码'),
          const SizedBox(height: 10),
          LegacyTextField(
            controller: _confirmPasswordController,
            hintText: '请再次输入支付密码',
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_submit()),
          ),
          const SizedBox(height: 20),
          LegacyActionButton(
            label: _submitting ? '提交中...' : '提交',
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 20),
          Center(
            child: InkWell(
              onTap: () => unawaited(_openService()),
              child: const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  children: <InlineSpan>[
                    TextSpan(text: '遇到问题，'),
                    TextSpan(
                      text: '联系客服',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
