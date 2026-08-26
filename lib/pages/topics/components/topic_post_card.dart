import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/posts/components/post_more_action_sheet.dart';
import 'package:b_flutter/routes/app_routes.dart';

class TopicPostCard extends StatelessWidget {
  const TopicPostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(bottom: 10),
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 48,
                      child: LegacyNetworkImage(
                        url: post.authorAvatarUrl,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 3),
                          Text(
                            post.authorNickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '${_relativeTime(post.createdAt)} • 投稿了视频',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showMoreActions(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 16,
                        ),
                        child: Icon(
                          CupertinoIcons.ellipsis_vertical,
                          color: AppColors.textTertiary,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    LegacyNetworkImage(
                      url: post.preferredCoverUrl,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black45,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 5,
                      child: Row(
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              child: Text(
                                _duration(post.durationSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_compactCount(post.viewCount)} 观看',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.accessBadgeText.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: PostAccessBadge(text: post.accessBadgeText),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: <Widget>[
                const _ActionLabel(
                  asset: 'assets/images/ic_topic_share.svg',
                  text: '转发',
                ),
                const _ActionLabel(
                  asset: 'assets/images/ic_topic_comment.svg',
                  text: '评论',
                ),
                _ActionLabel(
                  asset: 'assets/images/ic_topic_dianzan.svg',
                  text: _compactCount(post.likeCount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => PostMoreActionSheet(postId: post.id),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.asset, required this.text});

  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              asset,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                AppColors.textTertiary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactCount(int value) {
  if (value >= 10000) {
    final count = value / 10000;
    return '${count.toStringAsFixed(count >= 10 ? 0 : 1)}万';
  }
  return '$value';
}

String _duration(int seconds) {
  final value = seconds < 0 ? 0 : seconds;
  final minutes = value ~/ 60;
  return '$minutes:${(value % 60).toString().padLeft(2, '0')}';
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return '刚刚';
  if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
  if (difference.inDays < 1) return '${difference.inHours}小时前';
  if (difference.inDays < 30) return '${difference.inDays}天前';
  if (difference.inDays < 365) return '${difference.inDays ~/ 30}个月前';
  return '${difference.inDays ~/ 365}年前';
}
