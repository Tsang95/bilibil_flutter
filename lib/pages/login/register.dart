import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_birthday_field.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/pages/login/register_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  late final RegisterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(RegisterController());
  }

  @override
  void dispose() {
    Get.delete<RegisterController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '注册'),
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('账号'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.accountController,
                hintText: '请输入账号',
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('密码'),
              const SizedBox(height: 10),
              LegacyTextField(
                controller: _controller.passwordController,
                hintText: '请输入密码',
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              const LegacyFieldLabel('重置密码（生日验证）'),
              const SizedBox(height: 10),
              Obx(
                () => LegacyBirthdayField(
                  value: _controller.birthday.value,
                  onTap: _pickBirthday,
                ),
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

  Future<void> _pickBirthday() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    _controller.birthday.value = _formatDate(selected);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
