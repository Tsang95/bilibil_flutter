import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/auth_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/utils/toast.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (oldPassword.isEmpty) {
      showToast('请输入旧密码', type: ToastType.error);
      return;
    }
    if (newPassword.isEmpty) {
      showToast('请输入新密码', type: ToastType.error);
      return;
    }
    if (confirmPassword.isEmpty) {
      showToast('请输入确认密码', type: ToastType.error);
      return;
    }
    if (newPassword != confirmPassword) {
      showToast('两次密码不一致', type: ToastType.error);
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await AuthApi.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (!mounted) return;
      Get.back<void>();
      showToast('修改成功', type: ToastType.success);
    } catch (_) {
      // AuthApi presents the backend error toast.
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '修改登录密码'),
      body: dismissKeyboardWrapper(
        context,
        ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
          children: <Widget>[
            const LegacyFieldLabel('旧密码'),
            const SizedBox(height: 10),
            LegacyTextField(
              controller: _oldPasswordController,
              hintText: '请输入旧密码',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const LegacyFieldLabel('新密码'),
            const SizedBox(height: 10),
            LegacyTextField(
              controller: _newPasswordController,
              hintText: '请输入新密码',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const LegacyFieldLabel('确认密码'),
            const SizedBox(height: 10),
            LegacyTextField(
              controller: _confirmPasswordController,
              hintText: '请再次输入新密码',
              obscureText: true,
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
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
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
}
