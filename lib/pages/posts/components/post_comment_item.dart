import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/post_comment.dart';

class PostCommentItem extends StatelessWidget {
  const PostCommentItem({
    super.key,
    required this.comment,
    required this.onReply,
  });

  final PostComment comment;
  final ValueChanged<PostComment> onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox.square(
            dimension: 42,
            child: LegacyNetworkImage(
              url: comment.author.avatarUrl,
              borderRadius: BorderRadius.circular(21),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  comment.author.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(comment.createdAt),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () => onReply(comment),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '回复',
                      style: TextStyle(color: AppColors.info, fontSize: 11),
                    ),
                  ),
                ),
                if (comment.replies.isNotEmpty)
                  _ReplyPreview(replies: comment.replies, onReply: onReply),
                const SizedBox(height: 7),
                const Divider(height: 1, color: AppColors.divider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.replies, required this.onReply});

  final List<PostComment> replies;
  final ValueChanged<PostComment> onReply;

  @override
  Widget build(BuildContext context) {
    final visibleReplies = replies.take(3).toList(growable: false);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final reply in visibleReplies)
            InkWell(
              onTap: () => onReply(reply),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 11, height: 1.4),
                    children: <InlineSpan>[
                      TextSpan(
                        text: reply.author.nickname,
                        style: const TextStyle(color: AppColors.info),
                      ),
                      if (reply
                          .targetAuthor
                          .nickname
                          .isNotEmpty) ...<InlineSpan>[
                        const TextSpan(text: ' 回复 '),
                        TextSpan(
                          text: reply.targetAuthor.nickname,
                          style: const TextStyle(color: AppColors.info),
                        ),
                      ],
                      TextSpan(text: '：${reply.content}'),
                    ],
                  ),
                ),
              ),
            ),
          if (replies.length > visibleReplies.length)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '共 ${replies.length} 条回复',
                style: const TextStyle(color: AppColors.info, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
