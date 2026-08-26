import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

class HomePortraitPostCard extends StatelessWidget {
  const HomePortraitPostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 223,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  key: ValueKey<String>('home_portrait_cover_${post.id}'),
                  height: 153,
                  child: _PortraitCover(post: post),
                ),
                SizedBox(
                  key: ValueKey<String>('home_portrait_information_${post.id}'),
                  height: 70,
                  child: _PortraitInformation(post: post),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _count(int value) =>
      value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}万' : '$value';

  static String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
}

class _PortraitCover extends StatelessWidget {
  const _PortraitCover({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        LegacyNetworkImage(
          url: post.preferredCoverUrl,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
        ),
        if (post.accessBadgeText.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: PostAccessBadge(text: post.accessBadgeText),
          ),
        Positioned(
          left: 10,
          right: post.type != 5 && post.collectionType != 1 ? 48 : 10,
          bottom: 7,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/images/ic_video_play.svg',
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  HomePortraitPostCard._count(post.viewCount),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/images/ic_video_commend.svg',
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  HomePortraitPostCard._count(post.collectCount),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        if (post.type != 5 && post.collectionType != 1)
          Positioned(
            right: 10,
            bottom: 7,
            child: Text(
              HomePortraitPostCard._duration(post.durationSeconds),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _PortraitInformation extends StatelessWidget {
  const _PortraitInformation({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 5,
          top: 8,
          right: 5,
          height: 36,
          child: Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
        Positioned(
          left: 5,
          right: 54,
          bottom: 6,
          child: Text(
            post.authorNickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
        if (post.label.isNotEmpty)
          Positioned(
            right: 10,
            top: 47,
            child: _PortraitOutlineTag(text: post.label),
          ),
        if (post.isOriginal)
          const Positioned(
            right: 8,
            bottom: 5,
            child: _PortraitOutlineTag(text: '原创'),
          ),
      ],
    );
  }
}

class _PortraitOutlineTag extends StatelessWidget {
  const _PortraitOutlineTag({required this.text});

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
