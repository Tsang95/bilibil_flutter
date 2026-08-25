import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/auth_api.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

final class QuickRegisterController extends GetxController {
  final nicknameController = TextEditingController();
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final isSubmitting = false.obs;

  Future<void> generate() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final account = await AuthApi.generateAccount(lockText: '正在生成账号...');
      nicknameController.text = account.nickname;
      accountController.text = account.username;
      passwordController.text = account.password;
      showToast('账号生成成功', type: ToastType.success);
    } catch (_) {
      // ApiClient has already converted and displayed the failure.
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value || !_validate()) return;
    isSubmitting.value = true;
    try {
      final session = await AuthApi.register(
        nickname: nicknameController.text.trim(),
        username: accountController.text.trim(),
        password: passwordController.text,
        birthday: '',
        lockText: '注册中...',
      );
      await Get.find<UserStore>().activateSession(
        session,
        identityCardPassword: passwordController.text,
      );
      showToast('注册成功', type: ToastType.success);
      Get.back<bool>(result: true);
    } catch (_) {
      // ApiClient has already converted and displayed the failure.
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _validate() {
    if (nicknameController.text.trim().isEmpty) {
      showToast('请输入昵称', type: ToastType.warning);
      return false;
    }
    if (accountController.text.trim().isEmpty) {
      showToast('请输入账号', type: ToastType.warning);
      return false;
    }
    if (passwordController.text.isEmpty) {
      showToast('请输入密码', type: ToastType.warning);
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    nicknameController.dispose();
    accountController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
