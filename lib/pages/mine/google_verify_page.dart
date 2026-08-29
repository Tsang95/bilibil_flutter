import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/utils.dart';
import 'package:b_flutter/components/legacy_action_button.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/google_verify_data.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

typedef GoogleSecretLoader = Future<GoogleVerifyData> Function();

class GoogleVerifyPage extends StatefulWidget {
  const GoogleVerifyPage({super.key, this.loadSecret});

  final GoogleSecretLoader? loadSecret;

  @override
  State<GoogleVerifyPage> createState() => _GoogleVerifyPageState();
}

class _GoogleVerifyPageState extends State<GoogleVerifyPage> {
  final _codeController = TextEditingController();
  GoogleVerifyData? _data;
  Object? _error;
  bool _loading = true;
  bool _binding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader = widget.loadSecret ?? UserApi.createGoogleSecret;
      final data = await loader();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyKey() async {
    final key = _data?.key ?? '';
    if (key.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: key));
    showToast('复制成功', type: ToastType.success);
  }

  Future<void> _bind() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showToast('请输入验证码', type: ToastType.error);
      return;
    }
    final key = _data?.key ?? '';
    if (key.isEmpty || _binding) return;

    setState(() => _binding = true);
    try {
      await UserApi.bindGoogleSecret(key: key, code: code);
      if (mounted) await Get.offNamed<dynamic>(AppRoutes.googleBound);
    } catch (_) {
      // UserApi presents the legacy backend error toast.
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '谷歌验证码'),
        body: dismissKeyboardWrapper(
          context,
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: <Widget>[
              Center(
                child: _GoogleQrFrame(
                  data: _data,
                  loading: _loading,
                  error: _error,
                  onRetry: _load,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '谷歌秘钥',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _GoogleKeyField(keyValue: _data?.key ?? '', onCopy: _copyKey),
              const SizedBox(height: 20),
              const Text(
                '谷歌验证码',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _codeController,
                  maxLength: 6,
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: _GoogleFieldBorder.border,
                    enabledBorder: _GoogleFieldBorder.border,
                    focusedBorder: _GoogleFieldBorder.border,
                    errorBorder: _GoogleFieldBorder.border,
                    focusedErrorBorder: _GoogleFieldBorder.border,
                    hintText: '请输入谷歌验证码',
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LegacyActionButton(
                label: _binding ? '绑定中...' : '绑定',
                onPressed: _binding || _data == null ? null : _bind,
              ),
            ],
          ),
        ),
      );
}

class _GoogleQrFrame extends StatelessWidget {
  const _GoogleQrFrame({
    required this.data,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final GoogleVerifyData? data;
  final bool loading;
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        height: 160,
        margin: const EdgeInsets.only(top: 30),
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/v1/ic_google_bg.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : error != null
                ? TextButton(
                    onPressed: () => unawaited(onRetry()),
                    child: const Text('重试'),
                  )
                : data == null || data!.url.isEmpty
                    ? const SizedBox.shrink()
                    : CachedNetworkImage(
                        imageUrl: LegacyNetworkImage.resolveUrl(data!.url),
                        fit: BoxFit.fill,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
      );
}

class _GoogleKeyField extends StatelessWidget {
  const _GoogleKeyField({required this.keyValue, required this.onCopy});

  final String keyValue;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 10),
            Expanded(
                child: Text(keyValue, style: const TextStyle(fontSize: 14))),
            InkWell(
              onTap: keyValue.isEmpty ? null : onCopy,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
              child: Container(
                width: 60,
                height: double.infinity,
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(4)),
                ),
                child: const Text(
                  '复制',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
}

abstract final class _GoogleFieldBorder {
  static const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    borderSide: BorderSide(color: AppColors.divider),
  );
}
