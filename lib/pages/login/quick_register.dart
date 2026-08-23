import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/pages/login/quick_register_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';

class QuickRegisterPage extends StatefulWidget {
  const QuickRegisterPage({super.key});

  @override
  State<QuickRegisterPage> createState() => QuickRegisterPageState();
}

class QuickRegisterPageState extends State<QuickRegisterPage> {
  late final QuickRegisterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(QuickRegisterController());
  }

  @override
  void dispose() {
    Get.delete<QuickRegisterController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '快速注册'),
      body: dismissKeyboardWrapper(
        context,
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LegacyFieldLabel('昵称'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.nicknameController,
                hintText: '请输入昵称',
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('账号'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.accountController,
                hintText: '请输入账号',
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('密码'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.passwordController,
                hintText: '请输入密码',
              ),
              const SizedBox(height: 20),
              Obx(
                () => LegacyActionButton(
                  label: '注册',
                  onPressed: _controller.isSubmitting.value
                      ? null
                      : _controller.submit,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => LegacyActionButton(
                  label: '快捷生成',
                  outlined: true,
                  onPressed: _controller.isSubmitting.value
                      ? null
                      : _controller.generate,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Get.offNamed<void>(AppRoutes.login),
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
                          TextSpan(text: '已有账号'),
                          TextSpan(
                            text: '立即登录',
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
