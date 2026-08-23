import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/api/home_api.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/routes/app_routes.dart';

void openHomeAdvertisement(BannerItem banner) {
  unawaited(
    HomeApi.recordAdvertisementClick(
      banner.advertiseOrderId,
    ).catchError((_) {}),
  );

  if (banner.html.trim().isNotEmpty) {
    Get.toNamed<void>(AppRoutes.bannerHtml, arguments: banner.html);
    return;
  }

  final uri = Uri.tryParse(banner.outsideUrl.trim());
  if (uri != null && uri.hasScheme) {
    unawaited(launchUrl(uri));
  }
}
