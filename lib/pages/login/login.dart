import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/pages/login/login_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LoginController());
  }

  @override
  void dispose() {
    Get.delete<LoginController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LegacyAppBar(
        title: '登录',
        trailing: TextButton(
          onPressed: () => showToast('客服信息暂未配置'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: const Text('联系客服'),
        ),
      ),
      body: dismissKeyboardWrapper(
        context,
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LegacyFieldLabel('账号'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.accountController,
                hintText: '请输入账号',
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('密码'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.passwordController,
                hintText: '请输入密码',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('谷歌验证码（可选输入）'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.googleCodeController,
                hintText: '请输入谷歌验证码',
                keyboardType: TextInputType.number,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _controller.submit(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('忘记密码？', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => LegacyActionButton(
                  label: '登录',
                  onPressed: _controller.isSubmitting.value
                      ? null
                      : _controller.submit,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => LegacyActionButton(
                  label: '身份卡登录',
                  outlined: true,
                  onPressed: _controller.isSubmitting.value ||
                          _controller.isReadingIdentityCard.value
                      ? null
                      : _controller.importIdentityCard,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Get.offNamed<void>(AppRoutes.register),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(text: '没有账号，'),
                          TextSpan(
                            text: '点击注册',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
