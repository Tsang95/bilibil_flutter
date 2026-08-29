import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_flutter/common/styles.dart';

class LegacyTextField extends StatelessWidget {
  const LegacyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength = 20,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: AppColors.divider, width: 1),
    );
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        maxLength: maxLength,
        maxLines: 1,
        cursorColor: AppColors.textPrimary,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
        ).copyWith(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
