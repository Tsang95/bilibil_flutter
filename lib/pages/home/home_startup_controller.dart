import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/models/app_version.dart';
import 'package:b_flutter/pages/home/components/home_startup_dialogs.dart';

final class HomeStartupController {
  Future<void>? _startup;

  Future<void> start() => _startup ??= _run();

  Future<void> _run() async {
    final version = await _requestVersion();
    if (version != null && await _isNewerVersion(version)) {
      await showHomeVersionDialog(version);
    }

    await Get.dialog<void>(const HomeSuggestionDialog());
    await _requestPopupAdvertisement();
  }

  Future<AppVersion?> _requestVersion() async {
    EasyLoading.show(maskType: EasyLoadingMaskType.clear);
    try {
      return await HomeApi.getAppVersion();
    } catch (_) {
      return null;
    } finally {
      if (EasyLoading.isShow) EasyLoading.dismiss();
    }
  }

  Future<bool> _isNewerVersion(AppVersion version) async {
    try {
      final package = await PackageInfo.fromPlatform();
      final build = int.tryParse(package.buildNumber) ?? 0;
      return version.versionNumber > build;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestPopupAdvertisement() async {
    try {
      final banner = await HomeApi.getPopupAdvertisement();
      if (banner == null || banner.pictureUrl.trim().isEmpty) return;
      await Get.dialog<void>(HomePopupAdvertisementDialog(banner: banner));
    } catch (_) {
      // The legacy flow leaves the user on home if popup-ad retrieval fails.
    }
  }
}
