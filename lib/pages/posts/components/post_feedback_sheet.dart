import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/utils/toast.dart';

class PostFeedbackSheet extends StatefulWidget {
  const PostFeedbackSheet({
    super.key,
    required this.reasons,
    required this.onSubmit,
  });

  final List<PostFeedbackReason> reasons;
  final Future<void> Function(PostFeedbackReason reason, String content)
  onSubmit;

  @override
  State<PostFeedbackSheet> createState() => _PostFeedbackSheetState();
}

class _PostFeedbackSheetState extends State<PostFeedbackSheet> {
  final TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      showToast('请输入反馈意见', type: ToastType.warning);
      return;
    }
    if (_submitting || widget.reasons.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(widget.reasons[_selectedIndex], content);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // The shared submission feedback reports the backend error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Text('反馈原因', style: TextStyle(fontSize: 14)),
                      Positioned(
                        right: 4,
                        child: IconButton(
                          tooltip: '关闭',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0.5, color: AppColors.divider),
                for (var index = 0; index < widget.reasons.length; index++)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      index == _selectedIndex
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: index == _selectedIndex
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 18,
                    ),
                    title: Text(
                      widget.reasons[index].content,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: _submitting
                        ? null
                        : () => setState(() => _selectedIndex = index),
                  ),
                Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !_submitting,
                    maxLength: 300,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '请输入反馈意见',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () => unawaited(_submit()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.8,
                              ),
                            )
                          : const Text('提交'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
