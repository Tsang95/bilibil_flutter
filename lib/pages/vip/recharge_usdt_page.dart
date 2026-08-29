import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/utils/toast.dart';

class RechargeUsdtPage extends StatefulWidget {
  const RechargeUsdtPage({super.key, required this.order});

  final RechargeOrder order;

  @override
  State<RechargeUsdtPage> createState() => _RechargeUsdtPageState();
}

class _RechargeUsdtPageState extends State<RechargeUsdtPage> {
  static const Duration _paymentDuration = Duration(minutes: 30);

  final GlobalKey _qrCodeKey = GlobalKey();
  Timer? _timer;
  late final DateTime _expiresAt;
  int _secondsLeft = _paymentDuration.inSeconds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(_paymentDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final seconds = _expiresAt.difference(DateTime.now()).inSeconds;
    final next = seconds.clamp(0, _paymentDuration.inSeconds);
    if (next == _secondsLeft || !mounted) return;
    setState(() => _secondsLeft = next);
    if (next == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copyAddress() async {
    final address = widget.order.address.trim();
    if (address.isEmpty) {
      showToast('收款地址为空', type: ToastType.error);
      return;
    }
    await Clipboard.setData(ClipboardData(text: address));
    showToast('复制成功', type: ToastType.success);
  }

  Future<void> _saveQrCode() async {
    if (_saving) return;
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureQrCode();
      var result = await _saveImage(bytes);
      if (!_isSaveSuccessful(result) &&
          defaultTargetPlatform == TargetPlatform.android) {
        final permission = await Permission.storage.request();
        if (permission.isGranted) result = await _saveImage(bytes);
      }
      if (!_isSaveSuccessful(result)) {
        throw StateError('Image gallery save failed');
      }
      showToast('已保存到相册', type: ToastType.success);
    } catch (_) {
      showToast('二维码保存失败', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List> _captureQrCode() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _qrCodeKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('QR code is not ready');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('QR code encoding failed');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<Object?> _saveImage(Uint8List bytes) async =>
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'usdt_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

  bool _isSaveSuccessful(Object? result) {
    if (result is! Map) return result != null;
    final value = result['isSuccess'] ?? result['success'];
    return value == true || value == 1 || value?.toString() == 'true';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: 'USDT充值'),
        body: widget.order.address.trim().isEmpty
            ? const Center(child: Text('订单信息无效'))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  _OrderCard(
                    order: widget.order,
                    secondsLeft: _secondsLeft,
                    qrCodeKey: _qrCodeKey,
                    saving: _saving,
                    onSave: _saveQrCode,
                    onCopy: _copyAddress,
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: _RechargeNotices(),
                  ),
                ],
              ),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.secondsLeft,
    required this.qrCodeKey,
    required this.saving,
    required this.onSave,
    required this.onCopy,
  });

  final RechargeOrder order;
  final int secondsLeft;
  final GlobalKey qrCodeKey;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/v1/bg_usdt_recharge.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Image.asset('assets/images/v1/ic_usdt.png'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '充值金额：',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${_amount(order.usdtPrice)}USDT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '官方收款钱包地址',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text('USDT/TRC20', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        key: const ValueKey<String>('usdt_countdown'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEAEB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: Color(0xFFB78287),
                              fontSize: 11,
                            ),
                            children: <InlineSpan>[
                              const TextSpan(text: '请在'),
                              TextSpan(
                                text: _countdown(secondsLeft),
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              const TextSpan(text: '内完成支付'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  RepaintBoundary(
                    key: qrCodeKey,
                    child: ColoredBox(
                      color: const Color(0xFFF5F5F5),
                      child: SizedBox.square(
                        dimension: 130,
                        child: QrImageView(
                          data: order.address,
                          version: QrVersions.auto,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.address,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GradientButton(
                          label: saving ? '保存中...' : '保存二维码',
                          onTap: saving ? null : onSave,
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(
                        child: _GradientButton(label: '复制地址', onTap: onCopy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '转账金额请与充值金额一致，否则无法及时到账',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFFAAA9), Color(0xFFFF5D90)],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      );
}

class _RechargeNotices extends StatelessWidget {
  const _RechargeNotices();

  static const List<String> _items = <String>[
    '收款地址定期更换，请勿保存作为长期使用，收款前请确认与系统展示是否一致。',
    '请勿向上诉地址充值非USDT-TRC2O资产，否则资产将不可回。',
    '您充值至上诉地址后，需要整个网络节点的确认，2次网络确认后到账。',
    '请务必确认电脑及浏览器安全，防止信息被篡改或泄露。',
  ];

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '温馨提示',
            style: TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
          const SizedBox(height: 10),
          for (final item in _items) ...<Widget>[
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  TextSpan(text: item),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
}

String _amount(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String _countdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}
