import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/charge_member.dart';
import 'package:b_flutter/models/charge_subscription_product.dart';
import 'package:b_flutter/models/post_detail.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class ChargeUserPage extends StatefulWidget {
  const ChargeUserPage({
    super.key,
    required this.authorId,
    required this.fallbackAuthor,
  });

  final int authorId;
  final PostAuthor fallbackAuthor;

  @override
  State<ChargeUserPage> createState() => _ChargeUserPageState();
}

class _ChargeUserPageState extends State<ChargeUserPage> {
  List<ChargeSubscriptionProduct> _products =
      const <ChargeSubscriptionProduct>[];
  ChargeMember? _member;
  Object? _error;
  bool _loading = true;
  bool _submitting = false;
  int _selectedIndex = 0;

  ChargeMember get _displayMember {
    return _member ??
        ChargeMember(
          id: widget.authorId,
          nickname: widget.fallbackAuthor.nickname,
          avatarUrl: widget.fallbackAuthor.avatarUrl,
          subscriptionDays: 0,
        );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        UserApi.getChargeMember(userId: widget.authorId),
        UserApi.getChargeProducts(userId: widget.authorId),
      ]);
      if (!mounted) return;
      setState(() {
        _member = results[0] as ChargeMember;
        _products = results[1] as List<ChargeSubscriptionProduct>;
        _selectedIndex = 0;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || _products.isEmpty) return;
    final product = _products[_selectedIndex];
    setState(() => _submitting = true);
    try {
      await SubmissionFeedback.run<void>(
        action: () => UserApi.buySubscription(
          userId: widget.authorId,
          productId: product.id,
        ),
        loadingMessage: '充电中...',
        successMessage: '充电成功',
        fallbackErrorMessage: '充电失败，请稍后重试',
      );
      if (Get.isRegistered<UserStore>()) {
        Get.find<UserStore>().restoreSessionInBackground();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // SubmissionFeedback has already displayed the request error.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = _displayMember;
    final currentUser = Get.isRegistered<UserStore>()
        ? Get.find<UserStore>().user.value
        : null;
    final selected = _products.isEmpty ? null : _products[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _ChargeHeader(
              member: member,
              currentAvatarUrl: currentUser?.avatarUrl ?? '',
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '订阅后作者的所有视频免费可看',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
              ),
            ),
            Expanded(child: _buildProducts()),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: selected == null || _submitting
                      ? null
                      : () => unawaited(_submit()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 1.8,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/images/v1/ic_lightning.svg',
                              width: 13,
                              height: 13,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            Text(
                              ' ${member.subscriptionDays > 0 ? '继续充电' : '充电'} ￥${_priceText(selected?.price ?? 0)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: () => unawaited(_load()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('套餐加载失败，点击重试'),
        ),
      );
    }
    if (_products.isEmpty) {
      return const Center(
        child: Text(
          '该作者暂无可用的充电套餐',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 6,
        childAspectRatio: 115 / 70,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];
        final selected = index == _selectedIndex;
        return InkWell(
          onTap: _submitting
              ? null
              : () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      const TextSpan(
                        text: '￥',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: _priceText(product.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _priceText(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

class _ChargeHeader extends StatelessWidget {
  const _ChargeHeader({required this.member, required this.currentAvatarUrl});

  final ChargeMember member;
  final String currentAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset('assets/images/bg_user_charge.png', fit: BoxFit.fill),
          Positioned(
            top: 48,
            left: 14,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            ),
          ),
          Positioned(
            top: 52,
            right: 14,
            child: IconButton(
              onPressed: () => showToast('邀请中心正在重构', type: ToastType.info),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: SvgPicture.asset(
                'assets/images/ic_topic_share.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 33,
            child: SizedBox.square(
              dimension: 48,
              child: LegacyNetworkImage(
                url: currentAvatarUrl,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            right: 74,
            bottom: 33,
            child: SizedBox.square(
              dimension: 48,
              child: LegacyNetworkImage(
                url: member.avatarUrl,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 30,
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: member.nickname,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: ' ${member.subscriptionDays} ',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: '天',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 20,
            bottom: 57,
            child: Text(
              '您已累计陪伴',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
