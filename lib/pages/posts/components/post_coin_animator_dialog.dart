import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/utils/toast.dart';

/// Legacy post-coin interaction: select a coin, then tap 22娘 to send it.
class PostCoinAnimatorDialog extends StatefulWidget {
  const PostCoinAnimatorDialog({
    super.key,
    required this.initialBalance,
    required this.onTip,
  });

  final int initialBalance;
  final Future<void> Function(int count) onTip;

  @override
  State<PostCoinAnimatorDialog> createState() => _PostCoinAnimatorDialogState();
}

class _PostCoinAnimatorDialogState extends State<PostCoinAnimatorDialog> {
  static const _animationDuration = Duration(milliseconds: 150);
  static const _jumpPhaseDuration = Duration(milliseconds: 100);

  var _selectedIndex = 0;
  var _balance = 0;
  var _jumping = false;
  var _submitting = false;

  int get _tipCount => _selectedIndex + 1;

  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance;
  }

  void _selectCoin(int index) {
    if (_submitting || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _throwCoin() async {
    if (_submitting) return;
    if (_balance < _tipCount) {
      showToast('硬币不够', type: ToastType.warning);
      return;
    }
    setState(() => _jumping = true);
    await Future<void>.delayed(_jumpPhaseDuration);
    if (!mounted) return;
    await Future<void>.delayed(_jumpPhaseDuration);
    if (!mounted) return;
    setState(() {
      _jumping = false;
      _submitting = true;
    });
    try {
      await widget.onTip(_tipCount);
      if (!mounted) return;
      setState(() => _balance -= _tipCount);
      Navigator.of(context).pop();
    } catch (_) {
      // The detail controller reports the failed request to the user.
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleCoinDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 120) return;
    if (velocity < 0) {
      _selectCoin(1);
    } else {
      _selectCoin(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        key: const ValueKey<String>('post_coin_animator_dialog'),
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final coinTop = (constraints.maxHeight - 76) / 2;
            return Stack(
              children: <Widget>[
                Positioned(
                  top: coinTop,
                  left: 10,
                  right: 10,
                  height: 76,
                  child: Row(
                    children: <Widget>[
                      _CoinArrow(
                        asset: 'assets/images/v1/ic_arrow_left.svg',
                        enabled: _selectedIndex != 0,
                        onTap: () => _selectCoin(0),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: _handleCoinDrag,
                          child: _CoinSelector(
                            selectedIndex: _selectedIndex,
                            onSelect: _selectCoin,
                          ),
                        ),
                      ),
                      _CoinArrow(
                        asset: 'assets/images/v1/ic_arrow_right.svg',
                        enabled: _selectedIndex != 1,
                        onTap: () => _selectCoin(1),
                      ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: _animationDuration,
                  curve: Curves.linear,
                  top: coinTop + (_jumping ? 76 : 91),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      key: const ValueKey<String>('post_coin_person'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _throwCoin,
                      child: Image.asset(
                        'assets/images/v1/post_pay_coin_person.png',
                        width: 86,
                        height: 136,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: coinTop + 232,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '点击22娘投硬币',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
                Positioned(
                  top: coinTop + 254,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '硬币余额：$_balance',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconButton(
                      key: const ValueKey<String>('post_coin_close'),
                      tooltip: '关闭',
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        CupertinoIcons.xmark_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoinArrow extends StatelessWidget {
  const _CoinArrow({
    required this.asset,
    required this.enabled,
    required this.onTap,
  });

  final String asset;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 76,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: SvgPicture.asset(
          asset,
          width: 27,
          height: 27,
          colorFilter: ColorFilter.mode(
            enabled ? Colors.white : AppColors.textTertiary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _CoinSelector extends StatelessWidget {
  const _CoinSelector({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 256,
      height: 76,
      child: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: _PostCoinAnimatorDialogState._animationDuration,
            curve: Curves.linear,
            right: selectedIndex == 0 ? 90 : 193,
            top: selectedIndex == 0 ? 0 : 6,
            child: _CoinOption(
              index: 0,
              selected: selectedIndex == 0,
              onTap: onSelect,
            ),
          ),
          AnimatedPositioned(
            duration: _PostCoinAnimatorDialogState._animationDuration,
            curve: Curves.linear,
            right: selectedIndex == 1 ? 90 : 0,
            top: selectedIndex == 1 ? 0 : 6,
            child: _CoinOption(
              index: 1,
              selected: selectedIndex == 1,
              onTap: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinOption extends StatelessWidget {
  const _CoinOption({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 76.0 : 64.0;
    return AnimatedScale(
      scale: selected ? 1 : 0.84,
      duration: _PostCoinAnimatorDialogState._animationDuration,
      child: GestureDetector(
        key: ValueKey<String>('post_coin_option_${index + 1}'),
        onTap: () => onTap(index),
        child: Image.asset(
          index == 0
              ? 'assets/images/v1/post_pay_coin_1.png'
              : 'assets/images/v1/post_pay_coin_2.png',
          width: size,
          height: size,
        ),
      ),
    );
  }
}
