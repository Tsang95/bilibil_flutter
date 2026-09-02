import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/home/home_advertisement_action.dart';
import 'package:b_flutter/routes/app_routes.dart';

class HomeForumPostCard extends StatelessWidget {
  const HomeForumPostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed<void>(
        AppRoutes.postDetailPath(post.id),
        arguments: AppRoutes.postDetailArguments(post),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            _ForumCover(urls: post.coverUrls),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '#${post.categoryName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8566FF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _Stat(label: '购买', value: post.salesCount),
                  const SizedBox(width: 10),
                  _Stat(label: '浏览', value: post.viewCount),
                  const SizedBox(width: 10),
                  _Stat(label: '收藏', value: post.collectCount),
                  const SizedBox(width: 10),
                  _ForumAccessBadge(post: post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeForumAdCard extends StatelessWidget {
  const HomeForumAdCard({super.key, required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openHomeAdvertisement(banner),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                banner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: LegacyNetworkImage(
                url: banner.pictureUrl,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '#广告',
                style: TextStyle(color: Color(0xFF8566FF), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumCover extends StatelessWidget {
  const _ForumCover({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return urls.length == 1
        ? SizedBox(
            width: double.infinity,
            height: 200,
            child: LegacyNetworkImage(
              url: urls.first,
              borderRadius: BorderRadius.circular(4),
            ),
          )
        : _ForumImageRow(urls: urls);
  }
}

class _ForumImageRow extends StatelessWidget {
  const _ForumImageRow({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final visibleUrls = urls.take(3).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < visibleUrls.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: visibleUrls.length >= 3 ? 1 : 175 / 130,
                child: LegacyNetworkImage(
                  url: visibleUrls[index],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 12),
        children: <InlineSpan>[
          TextSpan(
            text: '$label：',
            style: const TextStyle(color: AppColors.textTertiary),
          ),
          TextSpan(text: _compact(value)),
        ],
      ),
    );
  }

  static String _compact(int value) =>
      value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}万' : '$value';
}

class _ForumAccessBadge extends StatelessWidget {
  const _ForumAccessBadge({required this.post});

  final PostSummary post;

  String get _text {
    if (post.price > 0) return '${post.price}金币';
    if (post.isVipOnly || post.unlockType == 2) return 'VIP';
    return '免费';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('home_forum_access_${post.id}'),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          _text,
          maxLines: 1,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
