import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/pages/mine/profile_text_edit_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/submission_feedback.dart';

/// Legacy personal profile form. The profile is always saved through the
/// member endpoint so global account chrome remains in sync.
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  UserStore get _store => Get.find<UserStore>();

  Future<void> _update(
    UserInfo user, {
    String? nickname,
    String? avatarUrl,
    int? gender,
    String? signature,
    String? backgroundUrl,
  }) async {
    if (_submitting) return;
    final updated = user.copyWith(
      nickname: nickname,
      avatarUrl: avatarUrl,
      gender: gender,
      signature: signature,
      backgroundUrl: backgroundUrl,
    );
    setState(() => _submitting = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => UserApi.updateProfile(
          nickname: updated.nickname,
          avatarUrl: updated.avatarUrl,
          gender: updated.gender,
          signature: updated.signature,
          backgroundUrl: updated.backgroundUrl,
        ),
        loadingMessage: '修改中...',
        successMessage: '修改成功',
        fallbackErrorMessage: '修改失败，请稍后重试',
      );
      _store.user.value = updated;
    } catch (_) {
      // SubmissionFeedback presents the legacy request failure state.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editText({
    required UserInfo user,
    required bool signature,
  }) async {
    final result = await Get.toNamed<dynamic>(
      AppRoutes.profileTextEdit,
      arguments: ProfileTextEditArguments(
        title: signature ? '个性签名' : '昵称',
        maxLength: signature ? 70 : 16,
        initialValue: signature ? user.signature : user.nickname,
      ),
    );
    if (result is! String) return;
    final value = result;
    if (!mounted) return;
    if (!signature && value.isEmpty) {
      await showOkAlertDialog(context: context, message: '昵称不能为空');
      return;
    }
    await _update(
      user,
      signature: signature ? value : null,
      nickname: signature ? null : value,
    );
  }

  Future<void> _selectImage(UserInfo user, {required bool avatar}) async {
    if (_submitting) return;
    final source = await showModalActionSheet<String>(
      context: context,
      title: avatar ? '选择头像' : '设置主页背景',
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (source != 'photo' && source != 'camera') return;
    final file = await _picker.pickImage(
      source: source == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
    if (file == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      final url = await SubmissionFeedback.run<String>(
        action: () => UserApi.uploadProfileImage(
          filePath: file.path,
          fileName: file.name,
        ),
        loadingMessage: '正在上传图片...',
        successMessage: '上传成功',
        fallbackErrorMessage: '图片上传失败，请稍后重试',
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await _update(
        user,
        avatarUrl: avatar ? url : null,
        backgroundUrl: avatar ? null : url,
      );
    } catch (_) {
      // SubmissionFeedback presents the upload failure state.
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '个人资料'),
        body: Obx(() {
          final user = _store.user.value;
          if (user == null) {
            return const Center(child: Text('请先登录'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            children: <Widget>[
              _ProfileRow(
                label: '头像',
                onTap: () => unawaited(_selectImage(user, avatar: true)),
                trailing: SizedBox.square(
                  dimension: 30,
                  child: LegacyNetworkImage(
                    url: user.avatarUrl,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              _ProfileRow(
                label: '昵称',
                onTap: () => unawaited(_editText(user: user, signature: false)),
                trailing:
                    Text(user.nickname, style: const TextStyle(fontSize: 14)),
              ),
              _GenderRow(
                gender: user.gender,
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          unawaited(_update(user, gender: value));
                        }
                      },
              ),
              _ProfileRow(
                label: '个性签名',
                onTap: () => unawaited(_editText(user: user, signature: true)),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    user.signature.isEmpty ? '介绍一下自己吧' : user.signature,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              _ProfileRow(
                label: '设置充电计划',
                onTap: () => Get.toNamed<void>(AppRoutes.setChargePrice),
                trailing: const Text(
                  '设置充电套餐价格',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
              _ProfileRow(
                label: '主页背景',
                onTap: () => unawaited(_selectImage(user, avatar: false)),
                trailing: user.backgroundUrl.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: 140,
                        height: 30,
                        child: LegacyNetworkImage(
                          url: user.backgroundUrl,
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
              ),
            ],
          );
        }),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.trailing,
    required this.onTap,
  });
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.divider, width: .5)),
          ),
          child: Row(
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              trailing,
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
}

class _GenderRow extends StatelessWidget {
  const _GenderRow({required this.gender, required this.onChanged});
  final int gender;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.divider, width: .5)),
        ),
        child: Row(
          children: <Widget>[
            const Text('性别', style: TextStyle(fontSize: 14)),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Radio<int>(
                  value: 1,
                  groupValue: gender,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
                const Text('男', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 14),
                Radio<int>(
                  value: 0,
                  groupValue: gender,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const Text('女', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
}
