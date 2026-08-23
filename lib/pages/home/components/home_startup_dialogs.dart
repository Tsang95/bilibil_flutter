import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/app_version.dart';
import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/pages/home/home_advertisement_action.dart';
import 'package:b_flutter/routes/app_routes.dart';

class HomeVersionDialog extends StatelessWidget {
  const HomeVersionDialog({super.key, required this.version});

  final AppVersion version;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final cardWidth = availableWidth < 320 ? availableWidth : 320.0;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: cardWidth,
              maxHeight: constraints.maxHeight / 2,
            ),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cardWidth,
                child: DecoratedBox(
                  key: const Key('home_version_dialog_card'),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '本站全新升级',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        version.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          child: Text(
                            version.description,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 28,
                        ),
                        child: Row(
                          children: <Widget>[
                            if (!version.isForced)
                              Expanded(
                                child: _VersionActionButton(
                                  label: '下次',
                                  onTap: Get.back<void>,
                                ),
                              ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _VersionActionButton(
                                label: '去升级',
                                onTap: () {
                                  final uri = Uri.tryParse(version.downloadUrl);
                                  if (uri != null && uri.hasScheme) {
                                    unawaited(launchUrl(uri));
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
            ),
          ),
        );
      },
    );
  }
}

class _VersionActionButton extends StatelessWidget {
  const _VersionActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class HomeSuggestionDialog extends StatelessWidget {
  const HomeSuggestionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () => Get.offNamed<void>(AppRoutes.suggestion),
            child: Image.asset(
              'assets/images/bg_dialog_suggestion.png',
              width: 315,
              height: 408,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: Get.back<void>,
            child: const Icon(
              CupertinoIcons.xmark_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePopupAdvertisementDialog extends StatelessWidget {
  const HomePopupAdvertisementDialog({super.key, required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Get.back<void>();
              openHomeAdvertisement(banner);
            },
            child: SizedBox(
              width: 315,
              height: 408,
              child: LegacyNetworkImage(
                url: banner.pictureUrl,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: Get.back<void>,
            child: const Icon(
              CupertinoIcons.xmark_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
