import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/utils/toast.dart';

/// Opens a legacy configuration URL and preserves its visible failure feedback.
Future<void> openConfiguredLink(
  String url, {
  required String unavailableMessage,
}) async {
  final target = Uri.tryParse(url.trim());
  if (target == null || target.scheme.isEmpty) {
    showToast(unavailableMessage, type: ToastType.info);
    return;
  }
  if (!await launchUrl(target)) {
    showToast('链接打开失败', type: ToastType.error);
  }
}
