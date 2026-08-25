import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:b_flutter/api/auth_api.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/identity_card_decoder.dart';
import 'package:b_flutter/utils/request_lock.dart';
import 'package:b_flutter/utils/toast.dart';

final class LoginController extends GetxController {
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final googleCodeController = TextEditingController();
  final isSubmitting = false.obs;
  final isReadingIdentityCard = false.obs;
  final ImagePicker _imagePicker = ImagePicker();
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );

  Future<void> submit() async {
    if (isSubmitting.value) return;
    final account = accountController.text.trim();
    final password = passwordController.text;
    if (account.isEmpty) {
      showToast('请输入账号', type: ToastType.warning);
      return;
    }
    if (password.isEmpty) {
      showToast('请输入密码', type: ToastType.warning);
      return;
    }

    isSubmitting.value = true;
    try {
      final session = await AuthApi.login(
        username: account,
        password: password,
        googleCode: googleCodeController.text.trim(),
        lockText: '登录中...',
      );
      await Get.find<UserStore>().activateSession(
        session,
        identityCardPassword: password,
      );
      showToast('登录成功', type: ToastType.success);
      Get.back<bool>(result: true);
    } catch (_) {
      // ApiClient has already converted and displayed the failure.
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> importIdentityCard() async {
    if (isReadingIdentityCard.value || isSubmitting.value) return;
    if (kIsWeb) {
      showToast('网页端暂不支持身份卡图片识别', type: ToastType.info);
      return;
    }

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    isReadingIdentityCard.value = true;
    try {
      final credentials = await RequestLockManager.instance.runLocked(() async {
        final capture = await _scannerController.analyzeImage(image.path);
        final payload = capture?.barcodes.firstOrNull?.rawValue ?? '';
        return IdentityCardDecoder().decode(payload);
      }, message: '正在识别身份卡...');
      accountController.text = credentials.username;
      passwordController.text = credentials.password;
      showToast('身份卡识别成功', type: ToastType.success);
    } catch (error) {
      showToast(error.toString(), type: ToastType.error);
      return;
    } finally {
      isReadingIdentityCard.value = false;
    }
    await submit();
  }

  @override
  void onClose() {
    accountController.dispose();
    passwordController.dispose();
    googleCodeController.dispose();
    unawaited(_scannerController.dispose());
    super.onClose();
  }
}
