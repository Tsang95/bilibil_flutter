import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/suggestion_reason.dart';
import 'package:b_flutter/utils/toast.dart';

class SuggestionPage extends StatefulWidget {
  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  final TextEditingController _textController = TextEditingController();
  List<SuggestionReason> _reasons = const <SuggestionReason>[];
  int _score = 2;
  int _reason = 0;
  bool _submitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    try {
      final reasons = await UserApi.getSuggestionReasons();
      if (mounted) setState(() => _reasons = reasons);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final content = _textController.text;
    if (content.trim().isEmpty) {
      showToast('请输入优化建议', type: ToastType.error);
      return;
    }
    setState(() => _submitting = true);
    try {
      await UserApi.submitSuggestion(
        type: _reason + 1,
        content: content,
        score: _score,
      );
      if (mounted) setState(() => _isSuccess = true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '调查问卷'),
      body: _isSuccess ? _buildSuccessView(context) : _buildContentView(),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'assets/images/bg_submin_suggestion_success.png',
            width: 200,
            height: 107,
          ),
          const SizedBox(height: 20),
          const Text(
            '您的反馈提交成功',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '官方采纳后赠送1-3天VIP会自动添加到您的账号。',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 220,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '返回首页',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/banner_suggestion.png',
            width: double.infinity,
            height: 72,
            fit: BoxFit.fill,
          ),
          const SizedBox(height: 10),
          _buildSatisfaction(),
          const SizedBox(height: 10),
          RichText(
            text: const TextSpan(
              children: <InlineSpan>[
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _SectionMark(),
                ),
                TextSpan(
                  text: '反馈原因',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '（必选）',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(15 / 255),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reasons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 7,
                childAspectRatio: 160 / 20,
              ),
              itemBuilder: (context, index) {
                final reason = _reasons[index];
                final selected = _reason == reason.id;
                return GestureDetector(
                  onTap: () => setState(() => _reason = reason.id),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        selected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 16,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.textTertiary),
              ),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 8,
                maxLength: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  hintText: '请输入优化建议',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _submit,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _submitting ? '提交中...' : '确认提交',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatisfaction() {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(15 / 255),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            '网站满意度',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          for (var index = 0; index < 5; index++)
            GestureDetector(
              onTap: () => setState(() => _score = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  _score >= index
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.star,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _SectionMark extends StatelessWidget {
  const _SectionMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 14,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
