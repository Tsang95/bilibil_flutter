import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';

/// Legacy two-action message dialog used by login and confirmation prompts.
class LegacyMessageDialog extends StatelessWidget {
  const LegacyMessageDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '确定',
    this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final hasCancel = cancelLabel != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ConstrainedBox(
        key: const ValueKey<String>('legacy_message_dialog_panel'),
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: <Widget>[
                      if (hasCancel) ...<Widget>[
                        Expanded(
                          child: _LegacyOutlineDialogButton(
                            label: cancelLabel!,
                            onTap:
                                onCancel ?? () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _LegacyFilledDialogButton(
                          label: confirmLabel,
                          onTap: onConfirm,
                        ),
                      ),
                    ],
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

enum LegacyAccessDialogAction { close, purchase, recharge, vip, login, charge }

/// Pixel-oriented reconstruction of the legacy coin/VIP access prompt.
class LegacyAccessDialog extends StatelessWidget {
  const LegacyAccessDialog({
    super.key,
    required this.price,
    required this.walletBalance,
    required this.nickname,
    required this.isVip,
  });

  final double price;
  final double walletBalance;
  final String nickname;
  final bool isVip;

  bool get _hasEnoughBalance => walletBalance >= price;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        key: const ValueKey<String>('legacy_access_dialog'),
        width: 315,
        height: 360,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Text(
                  '提示',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isVip ? '当前账户：$nickname' : '当前钱包余额：$walletBalance',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isVip ? '此贴为VIP专享，请购买VIP' : '当前帖子需要付费$price金币进行购买。',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              if (!isVip) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: Text(
                    !_hasEnoughBalance ? '余额不足，是否前往充值' : '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildChargePlan(context),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: isVip
                    ? _buildVipActions(context)
                    : _buildCoinActions(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargePlan(BuildContext context) {
    return Container(
      height: 85,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: _LegacyOutlineDialogButton(
                label: '加入up主充电计划。',
                primary: true,
                onTap: () =>
                    Navigator.of(context).pop(LegacyAccessDialogAction.charge),
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            '充电后，用户所有视频全部免费可看',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinActions(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _LegacyOutlineDialogButton(
              label: '关闭',
              onTap: () =>
                  Navigator.of(context).pop(LegacyAccessDialogAction.close),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LegacyFilledDialogButton(
              label: _hasEnoughBalance ? '我要购买' : '去充值',
              onTap: () => Navigator.of(context).pop(
                _hasEnoughBalance
                    ? LegacyAccessDialogAction.purchase
                    : LegacyAccessDialogAction.recharge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipActions(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 40,
          child: _LegacyFilledDialogButton(
            label: '去开通VIP',
            onTap: () =>
                Navigator.of(context).pop(LegacyAccessDialogAction.vip),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: _LegacyOutlineDialogButton(
            label: '已有账号？立即登录',
            primary: true,
            onTap: () =>
                Navigator.of(context).pop(LegacyAccessDialogAction.login),
          ),
        ),
      ],
    );
  }
}

class _LegacyFilledDialogButton extends StatelessWidget {
  const _LegacyFilledDialogButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyOutlineDialogButton extends StatelessWidget {
  const _LegacyOutlineDialogButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary ? AppColors.primary : AppColors.textTertiary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color, width: 1),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: color, fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
