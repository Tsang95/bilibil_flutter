import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

/// “最新”频道对应旧版横向信息流卡片。
class HomeLatestPostCard extends StatelessWidget {
  const HomeLatestPostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(
        AppRoutes.postDetailPath(post.id),
        arguments: AppRoutes.postDetailArguments(post),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = math.min(175.0, constraints.maxWidth * 0.48);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  height: 98,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: imageWidth,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            LegacyNetworkImage(
                              url: post.preferredCoverUrl,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            if (post.accessBadgeText.isNotEmpty)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: PostAccessBadge(
                                  text: post.accessBadgeText,
                                ),
                              ),
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
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
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _LatestPostInformation(post: post)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Divider(height: 0.5, color: AppColors.divider),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _duration(int seconds) {
    final safeSeconds = math.max(0, seconds);
    final minutes = safeSeconds ~/ 60;
    final remainder = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
}

class _LatestPostInformation extends StatelessWidget {
  const _LatestPostInformation({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.35),
        ),
        const Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFF6633).withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              '${_compactCount(post.collectCount)}点赞',
              style: const TextStyle(color: Color(0xFFFF6633), fontSize: 9),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textTertiary, width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  'UP',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 8),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                post.authorNickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/ic_video_play.svg',
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                AppColors.textTertiary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _compactCount(post.viewCount),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
            const Text(
              '  •  ',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
            ),
            Expanded(
              child: Text(
                _relativeTime(post.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
            const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ],
    );
  }

  static String _compactCount(int value) {
    if (value >= 10000) {
      final number = value / 10000;
      return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}万';
    }
    return '$value';
  }

  static String _relativeTime(DateTime? value) {
    if (value == null) return '';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.isNegative || difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
    if (difference.inDays < 1) return '${difference.inHours}小时前';
    if (difference.inDays < 30) return '${difference.inDays}天前';
    if (difference.inDays < 365) return '${difference.inDays ~/ 30}个月前';
    return '${difference.inDays ~/ 365}年前';
  }
}
