import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/post_access_badge.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/posts/components/post_feedback_sheet.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

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
      builder: (_) => _TopicPostMoreSheet(postId: post.id),
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

class _TopicPostMoreSheet extends StatefulWidget {
  const _TopicPostMoreSheet({required this.postId});

  final int postId;

  @override
  State<_TopicPostMoreSheet> createState() => _TopicPostMoreSheetState();
}

class _TopicPostMoreSheetState extends State<_TopicPostMoreSheet> {
  PostDetail? _detail;
  bool _collecting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final detail = await PostApi.getDetail(postId: widget.postId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
      showToast('帖子信息加载失败', type: ToastType.error);
    }
  }

  Future<void> _toggleCollect() async {
    if (_collecting) return;
    if (!TokenManager.instance.hasToken) {
      final result = await Get.toNamed(AppRoutes.login);
      if (result != true || !mounted) return;
    }
    final detail = _detail;
    if (detail == null) return;
    setState(() => _collecting = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => PostApi.toggleCollect(postId: widget.postId),
        loadingMessage: detail.isCollected ? '取消收藏中...' : '收藏中...',
        successMessage: detail.isCollected ? '已取消收藏' : '收藏成功',
      );
      if (mounted) {
        setState(() {
          _detail = detail.copyWith(isCollected: !detail.isCollected);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  Future<void> _openFeedback() async {
    if (!TokenManager.instance.hasToken) {
      final result = await Get.toNamed(AppRoutes.login);
      if (result != true || !mounted) return;
    }
    try {
      final reasons = await PostApi.getFeedbackReasons();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (reasons.isEmpty) {
        showToast('暂无可用的反馈原因', type: ToastType.warning);
        return;
      }
      await showModalBottomSheet<void>(
        context: Get.context!,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostFeedbackSheet(
          reasons: reasons,
          onSubmit: (reason, content) => SubmissionFeedback.run<void>(
            action: () => PostApi.sendFeedback(
              postId: widget.postId,
              reasonId: reason.id,
              content: content,
            ),
            loadingMessage: '正在提交反馈...',
            successMessage: '反馈提交成功',
          ),
        ),
      );
    } catch (_) {
      showToast('反馈原因加载失败', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 210,
        child: _detail == null
            ? const Center(
                child: SpinKitFadingCube(size: 24, color: AppColors.primary),
              )
            : Column(
                children: <Widget>[
                  const _SheetAction(
                    asset: 'assets/images/ic_topic_share.svg',
                    label: '分享',
                    color: AppColors.primary,
                  ),
                  const Divider(height: 0.5, indent: 20, endIndent: 20),
                  _SheetAction(
                    asset: 'assets/images/ic_topic_unfollow.svg',
                    label: _detail!.isCollected ? '取消关注' : '关注',
                    onTap: _toggleCollect,
                  ),
                  const Divider(height: 0.5, indent: 20, endIndent: 20),
                  _SheetAction(
                    asset: 'assets/images/ic_topic_report.svg',
                    label: '举报',
                    onTap: _openFeedback,
                  ),
                  const SizedBox(
                    height: 5,
                    child: ColoredBox(color: Color(0xFFF1F1F1)),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Text('取消', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.asset,
    required this.label,
    this.color,
    this.onTap,
  });

  final String asset;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                asset,
                width: 16,
                height: 16,
                colorFilter: color == null
                    ? null
                    : ColorFilter.mode(color!, BlendMode.srcIn),
              ),
              const SizedBox(width: 20),
              Text(label, style: const TextStyle(fontSize: 14)),
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
