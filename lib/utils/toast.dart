import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';

enum ToastType { text, success, error, warning, info }

final Map<String, DateTime> _recentToasts = <String, DateTime>{};
const Duration _duplicateWindow = Duration(milliseconds: 500);

void showToast(
  String message, {
  ToastType type = ToastType.text,
  Duration duration = const Duration(seconds: 2),
}) {
  final normalizedMessage = message.trim();
  if (normalizedMessage.isEmpty) return;

  final now = DateTime.now();
  final signature = '${type.name}:$normalizedMessage';
  final lastShownAt = _recentToasts[signature];
  if (lastShownAt != null && now.difference(lastShownAt) < _duplicateWindow) {
    return;
  }
  _recentToasts[signature] = now;
  _recentToasts.removeWhere(
    (_, shownAt) => now.difference(shownAt) > const Duration(seconds: 10),
  );

  BotToast.showCustomText(
    onlyOne: true,
    duration: duration,
    align: Alignment.center,
    toastBuilder: (_) => _ToastCard(message: normalizedMessage, type: type),
  );
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.type});

  final String message;
  final ToastType type;

  @override
  Widget build(BuildContext context) {
    final visual = _ToastVisual.from(type);
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.toastBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visual.icon != null) ...[
              Icon(visual.icon, color: visual.color, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToastVisual {
  const _ToastVisual(this.icon, this.color);

  final IconData? icon;
  final Color color;

  factory _ToastVisual.from(ToastType type) {
    return switch (type) {
      ToastType.text => const _ToastVisual(null, Colors.transparent),
      ToastType.success => const _ToastVisual(
          Icons.check_circle_rounded,
          AppColors.success,
        ),
      ToastType.error => const _ToastVisual(
          Icons.error_rounded,
          AppColors.error,
        ),
      ToastType.warning => const _ToastVisual(
          Icons.warning_amber_rounded,
          AppColors.warning,
        ),
      ToastType.info => const _ToastVisual(Icons.info_rounded, AppColors.info),
    };
  }
}
