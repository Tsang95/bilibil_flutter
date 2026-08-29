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
    this.placeholder,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveUrl(url);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth = _resolveCacheWidth(
          constraints.maxWidth,
          MediaQuery.devicePixelRatioOf(context),
        );
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
                    memCacheWidth: cacheWidth,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) =>
                        placeholder ??
                        const Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  static int? _resolveCacheWidth(double logicalWidth, double pixelRatio) {
    if (!logicalWidth.isFinite || logicalWidth <= 0 || pixelRatio <= 0) {
      return null;
    }
    return (logicalWidth * pixelRatio).round().clamp(1, 4096);
  }

  static String resolveUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final target = Uri.tryParse(trimmed);
    if (target?.hasScheme == true) return trimmed;
    final baseUrl = AppConfigStore.instance.config?.sourceBaseUrl ?? '';
    if (baseUrl.isEmpty) return trimmed;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase).resolve(trimmed).toString();
  }
}
