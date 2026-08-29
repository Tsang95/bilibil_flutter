import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';

class PostAccessBadge extends StatelessWidget {
  const PostAccessBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final isVip = text == 'VIP';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isVip
            ? const Color(0xCCFF6633)
            : AppColors.primary.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
