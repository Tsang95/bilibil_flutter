import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/auth_api.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

final class RegisterController extends GetxController {
  final nicknameController = TextEditingController();
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final birthday = ''.obs;
  final isSubmitting = false.obs;

  Future<void> submit() async {
    if (isSubmitting.value || !_validate()) return;
    isSubmitting.value = true;
    try {
      final session = await AuthApi.register(
        nickname: nicknameController.text.trim(),
        username: accountController.text.trim(),
        password: passwordController.text,
        birthday: birthday.value,
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
    final account = accountController.text.trim();
    if (account.isEmpty) {
      showToast('请输入账号', type: ToastType.warning);
      return false;
    }
    if (account.length < 6) {
      showToast('账号太短！', type: ToastType.warning);
      return false;
    }
    if (passwordController.text.isEmpty) {
      showToast('请输入密码', type: ToastType.warning);
      return false;
    }
    if (birthday.value.isEmpty) {
      showToast('请选择生日，以便密码忘记后重置密码', type: ToastType.warning);
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
