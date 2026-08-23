import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/auth_api.dart';
import 'package:b_flutter/utils/toast.dart';

final class ForgotPasswordController extends GetxController {
  final step = 1.obs;
  final accountController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final birthday = ''.obs;
  final isSubmitting = false.obs;

  void continueFromAccount() {
    if (accountController.text.trim().isEmpty) {
      showToast('请输入账号', type: ToastType.warning);
      return;
    }
    step.value = 2;
  }

  void continueFromBirthday() {
    if (birthday.value.isEmpty) {
      showToast('请输入您的生日', type: ToastType.warning);
      return;
    }
    step.value = 3;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    final password = newPasswordController.text;
    final confirmation = confirmPasswordController.text;
    if (password.isEmpty) {
      showToast('请输入新密码', type: ToastType.warning);
      return;
    }
    if (confirmation.isEmpty) {
      showToast('请再次输入新密码', type: ToastType.warning);
      return;
    }
    if (password != confirmation) {
      showToast('两次密码不一致', type: ToastType.warning);
      return;
    }

    isSubmitting.value = true;
    try {
      await AuthApi.recoverPassword(
        username: accountController.text.trim(),
        birthday: birthday.value,
        newPassword: password,
        confirmPassword: confirmation,
        lockText: '正在重置密码...',
      );
      showToast('重置密码成功，请登录', type: ToastType.success);
      Get.back<void>();
    } catch (_) {
      // ApiClient has already converted and displayed the failure.
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    accountController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
