import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

/// Two-column card used by the legacy post-tag result page.
class PostTagPostCard extends StatelessWidget {
  const PostTagPostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 98,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  LegacyNetworkImage(
                    url: post.preferredCoverUrl,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(height: 30, child: _CoverGradient()),
                  ),
                  if (post.accessBadgeText.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: PostAccessBadge(text: post.accessBadgeText),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Row(
                      children: <Widget>[
                        _CoverMetric(
                          iconAsset: 'assets/images/ic_video_play.svg',
                          value: _compactCount(post.viewCount),
                        ),
                        const SizedBox(width: 8),
                        _CoverMetric(
                          iconAsset: 'assets/images/ic_video_commend.svg',
                          value: _compactCount(post.collectCount),
                        ),
                        const Spacer(),
                        if (post.type != 5)
                          Text(
                            _duration(post.durationSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _TagPostInformation(post: post)),
          ],
        ),
      ),
    );
  }

  static String _compactCount(int value) {
    if (value >= 10000) {
      final compact = value / 10000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}万';
    }
    return '$value';
  }

  static String _duration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final remainder = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
}

class _CoverGradient extends StatelessWidget {
  const _CoverGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black54],
        ),
      ),
    );
  }
}

class _CoverMetric extends StatelessWidget {
  const _CoverMetric({required this.iconAsset, required this.value});

  final String iconAsset;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(iconAsset, width: 12, height: 12),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}

class _TagPostInformation extends StatelessWidget {
  const _TagPostInformation({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 5,
          top: 7,
          right: 5,
          height: 36,
          child: Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
        Positioned(
          left: 5,
          right: 48,
          bottom: 7,
          child: Text(
            post.authorNickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
        if (post.isOriginal)
          const Positioned(right: 5, bottom: 5, child: _TagOutline(text: '原创')),
        if (post.label.isNotEmpty)
          Positioned(right: 5, top: 46, child: _TagOutline(text: post.label)),
      ],
    );
  }
}

class _TagOutline extends StatelessWidget {
  const _TagOutline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.primary, fontSize: 9),
        ),
      ),
    );
  }
}
