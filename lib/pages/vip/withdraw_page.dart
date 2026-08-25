import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_pay_password_dialog.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/toast.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  static const int _minimumAmount = 1000;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  WithdrawLinkType _linkType = WithdrawLinkType.erc20;
  String _qrCodeUrl = '';
  Uint8List? _qrCodePreviewBytes;
  bool _uploading = false;
  bool _uploadFailed = false;
  bool _submitting = false;

  UserStore get _userStore => Get.find<UserStore>();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectQrCode() async {
    if (_uploading || _submitting) return;
    final source = await showModalActionSheet<String>(
      context: context,
      title: '选择封面图',
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (source != 'photo' && source != 'camera') return;
    final file = await _imagePicker.pickImage(
      source: source == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
    if (file == null || !mounted) return;

    Uint8List? previewBytes;
    try {
      previewBytes = await file.readAsBytes();
    } catch (_) {
      // 本地预览读取失败时仍继续上传，完成后使用服务端地址兜底。
    }
    if (!mounted) return;
    setState(() {
      _qrCodeUrl = '';
      _qrCodePreviewBytes = previewBytes;
      _uploading = true;
      _uploadFailed = false;
    });
    try {
      final url = await UserApi.uploadProfileImage(
        filePath: file.path,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() {
        _qrCodeUrl = url;
        _uploadFailed = false;
      });
      showToast('上传成功', type: ToastType.success);
    } catch (_) {
      if (mounted) setState(() => _uploadFailed = true);
      showToast('图片上传失败，请重新上传', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showSetPasswordPrompt() async {
    final shouldSet = await Get.dialog<bool>(
      LegacyMessageDialog(
        title: '提示',
        message: '您还没有设置支付密码，请先设置支付密码。',
        confirmLabel: '前往设置',
        onConfirm: () => Get.back(result: true),
      ),
    );
    if (shouldSet != true || !mounted) return;
    final entry = await Get.dialog<PayPasswordEntry>(
      const LegacyPayPasswordDialog(isSetting: true),
      barrierDismissible: false,
    );
    if (entry == null) return;
    try {
      await UserApi.setPayPassword(
        password: entry.password,
        confirmPassword: entry.confirmation,
      );
      _userStore.user.value = _userStore.user.value?.copyWith(
        hasPayPassword: true,
      );
      showToast('设置成功', type: ToastType.success);
      unawaited(_refreshUser());
    } catch (_) {
      // UserApi reports the backend failure.
    }
  }

  Future<void> _refreshUser() async {
    try {
      _userStore.user.value = await UserApi.getCurrentUser();
    } catch (_) {
      // A completed submission remains successful if background refresh fails.
    }
  }

  Future<void> _withdraw() async {
    final address = _addressController.text.trim();
    final rawAmount = _amountController.text.trim();
    final amount = int.tryParse(rawAmount);
    final balance = _userStore.user.value?.goldBalance ?? 0;
    if (address.isEmpty) {
      showToast('请输入提币地址', type: ToastType.info);
      return;
    }
    if (_qrCodeUrl.isEmpty) {
      showToast('请上传提币地址二维码', type: ToastType.info);
      return;
    }
    if (rawAmount.isEmpty || amount == null) {
      showToast('提现金币数量', type: ToastType.info);
      return;
    }
    if (amount > balance) {
      showToast('余额不足', type: ToastType.info);
      return;
    }
    if (amount < _minimumAmount) {
      showToast('最低提现金额数量1000', type: ToastType.info);
      return;
    }
    if (_userStore.user.value?.hasPayPassword != true) {
      await _showSetPasswordPrompt();
      return;
    }
    final password = await Get.dialog<String>(
      const LegacyPayPasswordDialog(),
      barrierDismissible: false,
    );
    if (password == null || _submitting || !mounted) return;
    setState(() => _submitting = true);
    try {
      await UserApi.withdrawGold(
        linkType: _linkType,
        coinAddress: address,
        qrCodeUrl: _qrCodeUrl,
        goldAmount: amount,
        payPassword: password,
      );
      _amountController.clear();
      showToast('提现成功', type: ToastType.success);
      unawaited(_refreshUser());
    } catch (_) {
      // UserApi reports the backend failure.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: LegacyAppBar(
      title: '提现',
      trailing: TextButton(
        onPressed: () => Get.toNamed<void>(AppRoutes.withdrawHistory),
        child: const Text('提现记录', style: TextStyle(fontSize: 14)),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 24),
      children: <Widget>[
        const _FieldLabel('链名称'),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WithdrawLinkType.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final type = WithdrawLinkType.values[index];
              final selected = type == _linkType;
              return InkWell(
                onTap: () => setState(() => _linkType = type),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const _FieldLabel('提币地址'),
        const SizedBox(height: 10),
        _WithdrawTextField(
          controller: _addressController,
          hintText: '请输入提币地址',
          maxLength: 50,
        ),
        const SizedBox(height: 10),
        const _FieldLabel('提币二维码'),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: _uploading ? null : () => unawaited(_selectQrCode()),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary),
              ),
              clipBehavior: Clip.antiAlias,
              child: _QrCodePreview(
                previewBytes: _qrCodePreviewBytes,
                url: _qrCodeUrl,
                uploading: _uploading,
                uploadFailed: _uploadFailed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '请输入真实有效的USDT充币地址和二维码，否则会导致提现不成功！',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        const _FieldLabel('提现数量'),
        Obx(
          () => Text(
            '可提现的金币余额：${_number(_userStore.user.value?.goldBalance ?? 0)}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            _WithdrawTextField(
              controller: _amountController,
              hintText: '最低提现金额数量1000',
              maxLength: 20,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              rightPadding: 58,
            ),
            TextButton(
              onPressed: () => _amountController.text = _number(
                _userStore.user.value?.goldBalance ?? 0,
              ),
              child: const Text('全部', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          children: <Widget>[
            Text(
              '手续费：0.00',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Spacer(),
            Text(
              '1金币=0.05USDT',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LegacyActionButton(
          label: _submitting ? '提现中...' : '确认提现',
          onPressed: _submitting ? null : _withdraw,
        ),
      ],
    ),
  );
}

class _QrCodePreview extends StatelessWidget {
  const _QrCodePreview({
    required this.previewBytes,
    required this.url,
    required this.uploading,
    required this.uploadFailed,
  });

  final Uint8List? previewBytes;
  final String url;
  final bool uploading;
  final bool uploadFailed;

  @override
  Widget build(BuildContext context) {
    final bytes = previewBytes;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (bytes != null)
          Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => url.isEmpty
                ? const _UploadPlaceholder()
                : LegacyNetworkImage(url: url, fit: BoxFit.cover),
          )
        else if (url.isNotEmpty)
          LegacyNetworkImage(url: url, fit: BoxFit.cover),
        if (bytes == null && url.isEmpty) const _UploadPlaceholder(),
        if (uploading)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.28),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        if (uploadFailed && !uploading)
          const Align(
            alignment: Alignment.bottomCenter,
            child: ColoredBox(
              color: Color(0xB3D32F2F),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '上传失败，请重新上传',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(CupertinoIcons.add, size: 16, color: AppColors.primary),
      Text('上传二维码', style: TextStyle(color: AppColors.primary, fontSize: 14)),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(fontSize: 14));
}

class _WithdrawTextField extends StatelessWidget {
  const _WithdrawTextField({
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.rightPadding = 10,
  });
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double rightPadding;
  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: AppColors.divider),
    );
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          counterText: '',
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          contentPadding: EdgeInsets.fromLTRB(10, 10, rightPadding, 10),
          filled: true,
          fillColor: AppColors.surface,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
