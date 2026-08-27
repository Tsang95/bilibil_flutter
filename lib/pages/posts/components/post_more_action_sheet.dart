import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/pages/posts/components/post_feedback_sheet.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

typedef PostMoreDetailLoader = Future<PostDetail> Function(int postId);
typedef PostMoreCollectAction = Future<void> Function(int postId);
typedef PostMoreFeedbackReasonLoader =
    Future<List<PostFeedbackReason>> Function();
typedef PostMoreFeedbackAction =
    Future<void> Function(int postId, int reasonId, String content);
typedef PostMoreLoginRequester = Future<bool> Function();

class PostMoreActionSheet extends StatefulWidget {
  const PostMoreActionSheet({
    super.key,
    required this.postId,
    this.initialDetail,
    this.detailLoader,
    this.collectAction,
    this.feedbackReasonLoader,
    this.feedbackAction,
    this.loginRequester,
  });

  final int postId;
  final PostDetail? initialDetail;
  final PostMoreDetailLoader? detailLoader;
  final PostMoreCollectAction? collectAction;
  final PostMoreFeedbackReasonLoader? feedbackReasonLoader;
  final PostMoreFeedbackAction? feedbackAction;
  final PostMoreLoginRequester? loginRequester;

  @override
  State<PostMoreActionSheet> createState() => _PostMoreActionSheetState();
}

class _PostMoreActionSheetState extends State<PostMoreActionSheet> {
  PostDetail? _detail;
  bool _collecting = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    if (_detail == null) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final loader = widget.detailLoader ?? _loadDetail;
      final detail = await loader(widget.postId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
      showToast('帖子信息加载失败', type: ToastType.error);
    }
  }

  Future<bool> _requireLogin() async {
    if (TokenManager.instance.hasToken) return true;
    final requester = widget.loginRequester;
    if (requester != null) return requester();
    final result = await Get.toNamed<dynamic>(AppRoutes.login);
    return result == true && mounted;
  }

  Future<void> _toggleCollect() async {
    if (_collecting || !await _requireLogin()) return;
    final detail = _detail;
    if (detail == null) return;
    setState(() => _collecting = true);
    try {
      final action = widget.collectAction ?? _togglePostCollect;
      await SubmissionFeedback.run<void>(
        action: () => action(widget.postId),
        loadingMessage: detail.isCollected ? '取消收藏中...' : '收藏中...',
        successMessage: detail.isCollected ? '已取消收藏' : '收藏成功',
      );
      if (mounted) {
        setState(() {
          _detail = detail.copyWith(isCollected: !detail.isCollected);
        });
      }
    } catch (_) {
      // SubmissionFeedback has already presented the API error.
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  Future<void> _openFeedback() async {
    if (!await _requireLogin()) return;
    try {
      final loader = widget.feedbackReasonLoader ?? PostApi.getFeedbackReasons;
      final reasons = await loader();
      if (!mounted) return;
      final pageContext = Navigator.of(context).context;
      Navigator.of(context).pop();
      if (reasons.isEmpty) {
        showToast('暂无可用的反馈原因', type: ToastType.warning);
        return;
      }
      if (!pageContext.mounted) return;
      await showModalBottomSheet<void>(
        context: pageContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostFeedbackSheet(
          reasons: reasons,
          onSubmit: (reason, content) {
            final action = widget.feedbackAction ?? _sendPostFeedback;
            return SubmissionFeedback.run<void>(
              action: () => action(widget.postId, reason.id, content),
              loadingMessage: '正在提交反馈...',
              successMessage: '反馈提交成功',
            );
          },
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
                    onTap: _collecting ? null : _toggleCollect,
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

Future<PostDetail> _loadDetail(int postId) => PostApi.getDetail(postId: postId);

Future<void> _togglePostCollect(int postId) =>
    PostApi.toggleCollect(postId: postId);

Future<void> _sendPostFeedback(int postId, int reasonId, String content) =>
    PostApi.sendFeedback(postId: postId, reasonId: reasonId, content: content);
