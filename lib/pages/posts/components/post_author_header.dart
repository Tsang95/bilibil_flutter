import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/post_detail.dart';

class PostAuthorHeader extends StatelessWidget {
  const PostAuthorHeader({
    super.key,
    required this.author,
    required this.submitting,
    required this.onMessage,
    required this.onFollow,
  });

  final PostAuthor author;
  final bool submitting;
  final VoidCallback onMessage;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: 46,
            child: LegacyNetworkImage(
              url: author.avatarUrl,
              borderRadius: BorderRadius.circular(23),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  author.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  author.signature.isNotEmpty
                      ? author.signature
                      : '${author.fanCount}粉丝 · ${author.workCount}作品',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            height: 26,
            child: OutlinedButton(
              onPressed: onMessage,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('私信', style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 55,
            height: 26,
            child: FilledButton(
              onPressed: submitting ? null : onFollow,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.72,
                ),
                disabledForegroundColor: Colors.white,
                shape: const StadiumBorder(),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: submitting
                  ? const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    )
                  : Text(
                      author.isFollowing ? '已关注' : '关注',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
