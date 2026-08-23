import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/post_detail.dart';

class PostActionBar extends StatelessWidget {
  const PostActionBar({
    super.key,
    required this.detail,
    required this.isSubmitting,
    required this.onLike,
    required this.onCollect,
    required this.onCoin,
    required this.onLine,
    required this.onFeedback,
    required this.onShare,
  });

  final PostDetail detail;
  final bool Function(String action) isSubmitting;
  final VoidCallback onLike;
  final VoidCallback onCollect;
  final VoidCallback onCoin;
  final VoidCallback onLine;
  final VoidCallback onFeedback;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          _ActionItem(
            label: _compactCount(detail.likeCount),
            active: detail.isLiked,
            submitting: isSubmitting('like'),
            onTap: onLike,
            icon: SvgPicture.asset(
              'assets/images/ic_thumb_up.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                detail.isLiked ? AppColors.primary : AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
          _ActionItem(
            label: _compactCount(detail.collectCount),
            active: detail.isCollected,
            submitting: isSubmitting('collect'),
            onTap: onCollect,
            icon: Icon(
              Icons.star_rounded,
              size: 22,
              color: detail.isCollected
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
          _ActionItem(
            label: _compactCount(detail.coinCount),
            active: detail.hasTippedCoin,
            submitting: isSubmitting('coin'),
            onTap: onCoin,
            icon: SvgPicture.asset(
              detail.hasTippedCoin
                  ? 'assets/images/v1/ic_payed_coin.svg'
                  : 'assets/images/v1/ic_pay_coin.svg',
              width: 21,
              height: 21,
            ),
          ),
          _ActionItem(
            label: '播放线路',
            active: false,
            submitting: false,
            onTap: onLine,
            icon: SvgPicture.asset(
              'assets/images/ic_post_action_line.svg',
              width: 20,
              height: 20,
            ),
          ),
          _ActionItem(
            label: '反馈',
            active: false,
            submitting: isSubmitting('feedback'),
            onTap: onFeedback,
            icon: SvgPicture.asset(
              'assets/images/ic_feedback.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
          _ActionItem(
            label: '分享',
            active: false,
            submitting: false,
            onTap: onShare,
            icon: SvgPicture.asset(
              'assets/images/ic_post_action_share.svg',
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }

  static String _compactCount(int value) {
    if (value < 10000) return '$value';
    final result = value / 10000;
    return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}万';
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.label,
    required this.active,
    required this.submitting,
    required this.onTap,
    required this.icon,
  });

  final String label;
  final bool active;
  final bool submitting;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: submitting ? null : onTap,
        radius: 30,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox.square(
              dimension: 22,
              child: submitting
                  ? const Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 1.8,
                      ),
                    )
                  : Center(child: icon),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
