import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';

class MoviePostCard extends StatelessWidget {
  const MoviePostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(
        AppRoutes.postDetailPath(post.id),
        arguments: AppRoutes.postDetailArguments(post),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                LegacyNetworkImage(
                  url: post.preferredCoverUrl,
                  borderRadius: BorderRadius.circular(10),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(height: 28, child: _MovieCoverGradient()),
                ),
                if (post.accessBadgeText.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PostAccessBadge(text: post.accessBadgeText),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: Row(
                    children: <Widget>[
                      _MovieMetric(
                        iconAsset: 'assets/images/ic_look_tag.svg',
                        value: _compactCount(post.viewCount),
                      ),
                      const Spacer(),
                      _MovieMetric(
                        iconAsset: 'assets/images/ic_commend_tag.svg',
                        value: _compactCount(post.collectCount),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _compactCount(int value) {
    if (value >= 10000) {
      final count = value / 10000;
      return '${count.toStringAsFixed(count >= 10 ? 0 : 1)}万';
    }
    return '$value';
  }
}

class _MovieCoverGradient extends StatelessWidget {
  const _MovieCoverGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black45],
        ),
      ),
    );
  }
}

class _MovieMetric extends StatelessWidget {
  const _MovieMetric({required this.iconAsset, required this.value});

  final String iconAsset;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(iconAsset, width: 16, height: 16),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
