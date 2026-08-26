import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

class HomePostCard extends StatelessWidget {
  const HomePostCard({super.key, required this.post, this.large = false});

  final PostSummary post;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: large
          ? _buildCard()
          : Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: 168, child: _buildCard()),
            ),
    );
  }

  Widget _buildCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            key: ValueKey<String>('home_post_cover_${post.id}'),
            height: large ? 200 : 98,
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
                  child: SizedBox(height: 30, child: _ImageGradient()),
                ),
                if (post.accessBadgeText.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: PostAccessBadge(text: post.accessBadgeText),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SvgPicture.asset(
                                  'assets/images/ic_video_play.svg',
                                  width: 12,
                                  height: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _compactCount(post.viewCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                if (!large) ...<Widget>[
                                  const SizedBox(width: 10),
                                  SvgPicture.asset(
                                    'assets/images/ic_video_commend.svg',
                                    width: 12,
                                    height: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _compactCount(post.collectCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (post.type != 5 && post.collectionType != 1)
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
          if (large)
            _PostInformation(post: post, large: true)
          else
            Flexible(child: _PostInformation(post: post, large: false)),
        ],
      ),
    );
  }

  static String _compactCount(int value) {
    if (value >= 10000) {
      final result = value / 10000;
      return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}万';
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

class _PostInformation extends StatelessWidget {
  const _PostInformation({required this.post, required this.large});

  final PostSummary post;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
        child: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      );
    }
    return SizedBox(
      key: ValueKey<String>('home_post_information_${post.id}'),
      height: 70,
      child: Stack(
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
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
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
          if (post.label.isNotEmpty)
            Positioned(
              right: 10,
              top: 47,
              child: _OutlineTag(text: post.label),
            ),
          if (post.isOriginal)
            const Positioned(
              right: 8,
              bottom: 5,
              child: _OutlineTag(text: '原创'),
            ),
        ],
      ),
    );
  }
}

class _ImageGradient extends StatelessWidget {
  const _ImageGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black54],
          stops: <double>[0.55, 1],
        ),
      ),
    );
  }
}

class _OutlineTag extends StatelessWidget {
  const _OutlineTag({required this.text});

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
