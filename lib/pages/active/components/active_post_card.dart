import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/posts/components/post_reward_sheet.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class ActivePostCard extends StatelessWidget {
  const ActivePostCard({super.key, required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
      child: ColoredBox(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildAuthor(),
              const SizedBox(height: 10),
              if (post.title.isNotEmpty)
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              _buildCovers(),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  _ActionItem(
                    icon: SvgPicture.asset(
                      'assets/images/ic_topic_comment.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: _compactCount(post.viewCount),
                  ),
                  _ActionItem(
                    icon: SvgPicture.asset(
                      'assets/images/ic_topic_dianzan.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: _compactCount(post.likeCount),
                  ),
                  _ActionItem(
                    icon: const Icon(
                      CupertinoIcons.star,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    label: _compactCount(post.collectCount),
                  ),
                  _ActionItem(
                    onTap: () => _openReward(context),
                    icon: SvgPicture.asset(
                      'assets/images/ic_post_gift.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: '打赏',
                  ),
                  _ActionItem(
                    onTap: () => _openInvite(context),
                    icon: SvgPicture.asset(
                      'assets/images/ic_topic_share.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: '分享',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthor() {
    return SizedBox(
      height: 35,
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: 35,
            child: LegacyNetworkImage(
              url: post.authorAvatarUrl,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          post.authorNickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (post.isOnline) ...<Widget>[
                        const SizedBox(width: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.greenAccent,
                              width: 1,
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            child: Text(
                              '在线',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${_relativeTime(post.createdAt)}•投稿了视频',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCovers() {
    final covers = post.coverUrls;
    if (covers.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          key: ValueKey<String>('active_single_cover_${post.id}'),
          height: 200,
          width: double.infinity,
          child: LegacyNetworkImage(url: covers.first),
        ),
      );
    }
    if (covers.isEmpty) return const SizedBox.shrink();
    final itemCount = math.min(9, covers.length);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GridView.builder(
        key: ValueKey<String>('active_cover_grid_${post.id}'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemBuilder: (context, index) => KeyedSubtree(
          key: ValueKey<String>('active_cover_${post.id}_$index'),
          child: LegacyNetworkImage(
            url: covers[index],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Future<bool> _requireLogin() async {
    if (TokenManager.instance.hasToken) return true;
    final result = await Get.toNamed(AppRoutes.login);
    return result == true;
  }

  Future<void> _openReward(BuildContext context) async {
    if (!await _requireLogin() || !context.mounted) return;
    try {
      final products = await PostApi.getRewardProducts();
      if (!context.mounted) return;
      if (products.isEmpty) {
        showToast('暂无可用的打赏选项', type: ToastType.warning);
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostRewardSheet(
          products: products,
          onReward: (product) => SubmissionFeedback.run<void>(
            action: () =>
                PostApi.reward(postId: post.id, productId: product.id),
            loadingMessage: '打赏中...',
            successMessage: '打赏成功',
          ),
        ),
      );
    } catch (_) {
      showToast('打赏选项加载失败', type: ToastType.error);
    }
  }

  Future<void> _openInvite(BuildContext context) async {
    if (!await _requireLogin() || !context.mounted) return;
    unawaited(Get.toNamed<void>(AppRoutes.invite));
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label, this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon,
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
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
