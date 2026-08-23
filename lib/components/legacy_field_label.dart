import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';

class LegacyFieldLabel extends StatelessWidget {
  const LegacyFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    );
  }
}
