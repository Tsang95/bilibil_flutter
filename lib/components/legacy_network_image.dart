import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/stores/app_config_store.dart';

class LegacyNetworkImage extends StatelessWidget {
  const LegacyNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveUrl(url);
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: AppColors.surfaceMuted,
        child: resolvedUrl.isEmpty
            ? const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.textTertiary,
                ),
              )
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: fit,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, _) => const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
      ),
    );
  }

  static String resolveUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('http')) return trimmed;
    final baseUrl = AppConfigStore.instance.config?.sourceBaseUrl ?? '';
    if (baseUrl.isEmpty) return trimmed;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase).resolve(trimmed).toString();
  }
}
