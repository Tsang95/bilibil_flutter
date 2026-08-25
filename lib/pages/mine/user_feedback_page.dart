import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

/// Legacy free-form product suggestion page, separate from the survey form.
class UserFeedbackPage extends StatefulWidget {
  const UserFeedbackPage({super.key});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final TextEditingController _feedback = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _feedback.text.trim();
    if (content.isEmpty) {
      showToast('请填写您的建议', type: ToastType.error);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => UserApi.submitUserFeedback(content: content),
        loadingMessage: '提交中...',
        successMessage: '提交成功',
        fallbackErrorMessage: '提交失败，请稍后重试',
      );
      if (mounted) Get.back<void>();
    } catch (_) {
      // SubmissionFeedback presents the request failure state.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '用户建议'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('请提供以下信息以便更好的处理您的建议：', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: TextField(
              controller: _feedback,
              maxLength: 500,
              maxLines: null,
              minLines: 6,
              decoration: const InputDecoration(
                hintText: '烦请详细描述您的建议，我们会用心做到最好',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LegacyActionButton(
            label: '提交',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    ),
  );
}
