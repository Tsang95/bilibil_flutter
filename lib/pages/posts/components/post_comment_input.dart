import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/post_comment.dart';

class PostCommentInput extends StatelessWidget {
  const PostCommentInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.replyTo,
    required this.submitting,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PostComment? replyTo;
  final bool submitting;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !submitting,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: replyTo == null
                          ? '说点什么吧'
                          : '回复给：${replyTo!.author.nickname}',
                      hintStyle: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                      suffixIcon: replyTo == null
                          ? null
                          : IconButton(
                              tooltip: '取消回复',
                              padding: EdgeInsets.zero,
                              onPressed: onCancelReply,
                              icon: const Icon(Icons.close_rounded, size: 16),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                height: 36,
                child: FilledButton(
                  onPressed: submitting ? null : onSend,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        )
                      : const Text('发送', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
