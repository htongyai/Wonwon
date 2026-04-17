import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxWidth = 800;
  static const int maxHeight = 800;

  static Widget getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: maxWidth,
      memCacheHeight: maxHeight,
      maxWidthDiskCache: maxWidth,
      maxHeightDiskCache: maxHeight,
      cacheManager: DefaultCacheManager(),
      placeholder:
          (context, url) =>
              placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, url, error) =>
              errorWidget ?? const Icon(Icons.error_outline, color: Colors.red),
    );
  }

  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      await precacheImage(NetworkImage(url), context);
    }
  }

  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }
}
