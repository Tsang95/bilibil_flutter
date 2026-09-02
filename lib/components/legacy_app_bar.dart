import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/common/styles.dart';

class LegacyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LegacyAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.trailingRightInset = 0,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final double trailingRightInset;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(49);

  @override
  Widget build(BuildContext context) {
    final sideWidth = 72 + trailingRightInset;
    return AppBar(
      toolbarHeight: 48,
      automaticallyImplyLeading: false,
      shape: const Border(
        bottom: BorderSide(color: AppColors.divider, width: 0.5),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(
            width: sideWidth,
            child: showBack
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: '返回',
                      onPressed: onBack ?? Get.back<void>,
                      icon: const Icon(CupertinoIcons.chevron_back, size: 20),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: sideWidth,
            child: Padding(
              padding: EdgeInsets.only(right: trailingRightInset),
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ),
        ],
      ),
    );
  }
}
