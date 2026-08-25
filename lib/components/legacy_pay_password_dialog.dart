import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import 'package:b_flutter/common/styles.dart';

final class PayPasswordEntry {
  const PayPasswordEntry({required this.password, required this.confirmation});

  final String password;
  final String confirmation;
}

/// Legacy six-digit payment-password dialog used by wallet submissions.
class LegacyPayPasswordDialog extends StatefulWidget {
  const LegacyPayPasswordDialog({super.key, this.isSetting = false});

  final bool isSetting;

  @override
  State<LegacyPayPasswordDialog> createState() =>
      _LegacyPayPasswordDialogState();
}

class _LegacyPayPasswordDialogState extends State<LegacyPayPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _message = '请输入支付密码';
  String _firstPassword = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _complete(String pin) {
    if (!widget.isSetting) {
      Navigator.of(context).pop(pin);
      return;
    }
    if (_firstPassword.isEmpty) {
      setState(() {
        _firstPassword = pin;
        _message = '请再输入一次';
        _controller.clear();
      });
      _focusNode.requestFocus();
      return;
    }
    Navigator.of(
      context,
    ).pop(PayPasswordEntry(password: _firstPassword, confirmation: pin));
  }

  @override
  Widget build(BuildContext context) {
    const pinTheme = PinTheme(
      width: 42,
      height: 50,
      textStyle: TextStyle(fontSize: 22, color: Color(0xFF1E3C57)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.fromBorderSide(
          BorderSide(color: Color.fromRGBO(23, 171, 144, 0.4)),
        ),
      ),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        key: const ValueKey<String>('legacy_pay_password_dialog'),
        width: 320,
        height: 260,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Text('提示', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 28),
              Text(_message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Pinput(
                  length: 6,
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  obscureText: true,
                  obscuringCharacter: '●',
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  defaultPinTheme: pinTheme,
                  focusedPinTheme: pinTheme.copyWith(
                    decoration: pinTheme.decoration?.copyWith(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF17AB90)),
                    ),
                  ),
                  submittedPinTheme: pinTheme.copyWith(
                    decoration: pinTheme.decoration?.copyWith(
                      border: Border.all(color: const Color(0xFF17AB90)),
                    ),
                  ),
                  onCompleted: _complete,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _DialogButton(
                        label: '取消',
                        outlined: true,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogButton(
                        label: '确定',
                        onTap: () {
                          if (_controller.text.length == 6) {
                            _complete(_controller.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : AppColors.primary,
            borderRadius: BorderRadius.circular(50),
            border: outlined ? Border.all(color: AppColors.primary) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: outlined ? AppColors.primary : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
