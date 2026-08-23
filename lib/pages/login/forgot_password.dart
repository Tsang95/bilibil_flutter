import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_birthday_field.dart';
import 'package:b_flutter/components/legacy_field_label.dart';
import 'package:b_flutter/components/legacy_text_field.dart';
import 'package:b_flutter/pages/login/forgot_password_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final ForgotPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ForgotPasswordController());
  }

  @override
  void dispose() {
    Get.delete<ForgotPasswordController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '忘记密码'),
      body: dismissKeyboardWrapper(
        context,
        Column(
          children: [
            Obx(() => _StepHeader(currentStep: _controller.step.value)),
            Expanded(
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: switch (_controller.step.value) {
                    2 => _BirthdayStep(
                      key: const ValueKey<int>(2),
                      value: _controller.birthday.value,
                      onPick: _pickBirthday,
                      onContinue: _controller.continueFromBirthday,
                    ),
                    3 => _PasswordStep(
                      key: const ValueKey<int>(3),
                      newPasswordController: _controller.newPasswordController,
                      confirmPasswordController:
                          _controller.confirmPasswordController,
                      submitting: _controller.isSubmitting.value,
                      onSubmit: _controller.submit,
                    ),
                    _ => _AccountStep(
                      key: const ValueKey<int>(1),
                      controller: _controller.accountController,
                      onContinue: _controller.continueFromAccount,
                    ),
                  },
                ),
              ),
            ),
          ],
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
    final month = selected.month.toString().padLeft(2, '0');
    final day = selected.day.toString().padLeft(2, '0');
    _controller.birthday.value = '${selected.year}-$month-$day';
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Row(
        children: [
          _StepItem(number: 1, label: '输入账号', active: currentStep >= 1),
          _StepLine(active: currentStep >= 2),
          _StepItem(number: 2, label: '输入生日', active: currentStep >= 2),
          _StepLine(active: currentStep >= 3),
          _StepItem(number: 3, label: '重置密码', active: currentStep >= 3),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.label,
    required this.active,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFFE5E5E5);
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
            border: Border.all(color: color),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: active ? Colors.white : color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.only(bottom: 27),
        color: active ? AppColors.primary : const Color(0xFFE5E5E5),
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  final TextEditingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        const LegacyFieldLabel('账号'),
        const SizedBox(height: 10),
        LegacyTextField(controller: controller, hintText: '请输入账号'),
        const SizedBox(height: 20),
        LegacyActionButton(label: '确定', onPressed: onContinue),
      ],
    );
  }
}

class _BirthdayStep extends StatelessWidget {
  const _BirthdayStep({
    super.key,
    required this.value,
    required this.onPick,
    required this.onContinue,
  });

  final String value;
  final VoidCallback onPick;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        const LegacyFieldLabel('生日验证'),
        const SizedBox(height: 10),
        LegacyBirthdayField(value: value, onTap: onPick),
        const SizedBox(height: 20),
        LegacyActionButton(label: '确定', onPressed: onContinue),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        const LegacyFieldLabel('新密码'),
        const SizedBox(height: 10),
        LegacyTextField(
          controller: newPasswordController,
          hintText: '请输入新密码',
          obscureText: true,
        ),
        const SizedBox(height: 20),
        const LegacyFieldLabel('确认新密码'),
        const SizedBox(height: 10),
        LegacyTextField(
          controller: confirmPasswordController,
          hintText: '请再次输入新密码',
          obscureText: true,
        ),
        const SizedBox(height: 20),
        LegacyActionButton(
          label: '确定',
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    );
  }
}
