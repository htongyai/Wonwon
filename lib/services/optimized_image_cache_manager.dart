import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Optimized image cache manager with intelligent caching strategies
class OptimizedImageCacheManager {
  static final OptimizedImageCacheManager _instance =
      OptimizedImageCacheManager._internal();
  factory OptimizedImageCacheManager() => _instance;
  OptimizedImageCacheManager._internal();

  // Dependencies
  final UnifiedMemoryManager _memoryManager = UnifiedMemoryManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Cache managers for different image types
  late final CacheManager _shopImageCache;
  late final CacheManager _profileImageCache;
  late final CacheManager _generalImageCache;

  // Configuration
  static const Duration _shopImageCacheDuration = Duration(days: 7);
  static const Duration _profileImageCacheDuration = Duration(days: 3);
  static const Duration _generalImageCacheDuration = Duration(days: 1);

  // Image size limits
  static const int _maxImageWidth = 1200;
  static const int _maxImageHeight = 1200;

  // Preloading queue
  final Set<String> _preloadingUrls = {};
  final Queue<String> _preloadQueue = Queue();
  bool _isPreloading = false;

  /// Initialize the image cache manager
  Future<void> initialize() async {
    appLog('OptimizedImageCacheManager: Initializing...');

    // Initialize specialized cache managers
    _shopImageCache = CacheManager(
      Config(
        'shop_images',
        stalePeriod: _shopImageCacheDuration,
        maxNrOfCacheObjects: 500,
        repo: JsonCacheInfoRepository(databaseName: 'shop_images'),
        fileService: HttpFileService(),
      ),
    );

    _profileImageCache = CacheManager(
      Config(
        'profile_images',
        stalePeriod: _profileImageCacheDuration,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'profile_images'),
        fileService: HttpFileService(),
      ),
    );

    _generalImageCache = CacheManager(
      Config(
        'general_images',
        stalePeriod: _generalImageCacheDuration,
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: 'general_images'),
        fileService: HttpFileService(),
      ),
    );

    appLog('OptimizedImageCacheManager: Initialized successfully');
  }

  /// Get optimized cached image widget
  Widget getCachedImage({
    required String imageUrl,
    required ImageType imageType,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    MemoryPriority priority = MemoryPriority.normal,
    bool enableHeroAnimation = false,
    String? heroTag,
  }) {
    final cacheManager = _getCacheManagerForType(imageType);
    final optimizedUrl = _getOptimizedImageUrl(imageUrl, width, height);

    // Register with memory manager
    _memoryManager.registerImageCache(
      optimizedUrl,
      _estimateImageSize(width, height),
      priority: priority,
    );

    Widget imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl,
      cacheManager: cacheManager,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: _getMemCacheWidth(width),
      memCacheHeight: _getMemCacheHeight(height),
      maxWidthDiskCache: _getMaxDiskCacheWidth(imageType),
      maxHeightDiskCache: _getMaxDiskCacheHeight(imageType),
      placeholder:
          (context, url) => _buildPlaceholder(placeholder, width, height),
      errorWidget:
          (context, url, error) =>
              _buildErrorWidget(errorWidget, error, width, height),
      imageBuilder: (context, imageProvider) {
        // Track image access
        _memoryManager.onImageAccessed(optimizedUrl);
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );

    // Wrap with hero animation if enabled
    if (enableHeroAnimation && heroTag != null) {
      imageWidget = Hero(tag: heroTag, child: imageWidget);
    }

    return MemoryManagedWidget(
      memoryKey: 'image_$optimizedUrl',
      priority: priority,
      child: imageWidget,
    );
  }

  /// Preload images for better performance
  Future<void> preloadImages(
    List<String> imageUrls, {
    ImageType imageType = ImageType.general,
    MemoryPriority priority = MemoryPriority.normal,
  }) async {
    if (_isPreloading) {
      // Add to queue
      for (final url in imageUrls) {
        if (!_preloadingUrls.contains(url)) {
          _preloadQueue.add(url);
        }
      }
      return;
    }

    _isPreloading = true;
    _performanceMonitor.startOperation('image_preloading');

    try {
      final cacheManager = _getCacheManagerForType(imageType);

      for (final url in imageUrls) {
        if (_preloadingUrls.contains(url)) continue;

        _preloadingUrls.add(url);

        try {
          await cacheManager.downloadFile(url);
          _memoryManager.registerImageCache(
            url,
            _estimateImageSize(null, null),
            priority: priority,
          );
          appLog('OptimizedImageCacheManager: Preloaded image: $url');
        } catch (e) {
          appLog(
            'OptimizedImageCacheManager: Failed to preload image $url: $e',
          );
        }

        _preloadingUrls.remove(url);
      }

      // Process queue
      while (_preloadQueue.isNotEmpty) {
        final url = _preloadQueue.removeFirst();
        if (!_preloadingUrls.contains(url)) {
          await preloadImages([url], imageType: imageType, priority: priority);
        }
      }
    } finally {
      _isPreloading = false;
      _performanceMonitor.endOperation('image_preloading');
    }
  }

  /// Clear specific cache type
  Future<void> clearCache(ImageType imageType) async {
    final cacheManager = _getCacheManagerForType(imageType);
    await cacheManager.emptyCache();
    appLog('OptimizedImageCacheManager: Cleared ${imageType.name} cache');
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await Future.wait([
      _shopImageCache.emptyCache(),
      _profileImageCache.emptyCache(),
      _generalImageCache.emptyCache(),
    ]);
    appLog('OptimizedImageCacheManager: Cleared all caches');
  }

  /// Get cache statistics
  Future<ImageCacheStatistics> getCacheStatistics() async {
    final shopStats = await _getCacheStats(_shopImageCache);
    final profileStats = await _getCacheStats(_profileImageCache);
    final generalStats = await _getCacheStats(_generalImageCache);

    return ImageCacheStatistics(
      shopImages: shopStats,
      profileImages: profileStats,
      generalImages: generalStats,
      memoryStats: _memoryManager.getMemoryStats().imageCacheStats,
    );
  }

  /// Optimize cache based on memory pressure
  Future<void> optimizeCache() async {
    _performanceMonitor.startOperation('image_cache_optimization');

    try {
      // Get current memory stats
      final memoryStats = _memoryManager.getMemoryStats();

      // If memory pressure is high, clear least used images
      if (memoryStats.imageCacheStats.totalEntries > 200) {
        appLog(
          'OptimizedImageCacheManager: High memory pressure, optimizing cache',
        );

        // Clear general images first (lowest priority)
        await _generalImageCache.emptyCache();

        // If still high pressure, clear older profile images
        if (memoryStats.imageCacheStats.totalEntries > 150) {
          await _clearOldCacheEntries(_profileImageCache, Duration(days: 1));
        }

        // As last resort, clear older shop images
        if (memoryStats.imageCacheStats.totalEntries > 100) {
          await _clearOldCacheEntries(_shopImageCache, Duration(days: 3));
        }
      }
    } finally {
      _performanceMonitor.endOperation('image_cache_optimization');
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Get cache manager for specific image type
  CacheManager _getCacheManagerForType(ImageType imageType) {
    switch (imageType) {
      case ImageType.shop:
        return _shopImageCache;
      case ImageType.profile:
        return _profileImageCache;
      case ImageType.general:
        return _generalImageCache;
    }
  }

  /// Get optimized image URL with size parameters
  String _getOptimizedImageUrl(
    String originalUrl,
    double? width,
    double? height,
  ) {
    // If the URL already has parameters or is not optimizable, return as-is
    if (!originalUrl.startsWith('http') || originalUrl.contains('?')) {
      return originalUrl;
    }

    // Add size optimization parameters for supported services
    final params = <String>[];

    if (width != null) {
      params.add('w=${width.toInt()}');
    }
    if (height != null) {
      params.add('h=${height.toInt()}');
    }

    // Add quality parameter
    params.add('q=85');

    if (params.isNotEmpty) {
      return '$originalUrl?${params.join('&')}';
    }

    return originalUrl;
  }

  /// Get memory cache width
  int? _getMemCacheWidth(double? width) {
    if (width == null) return _maxImageWidth;
    return (width * 2).toInt().clamp(100, _maxImageWidth);
  }

  /// Get memory cache height
  int? _getMemCacheHeight(double? height) {
    if (height == null) return _maxImageHeight;
    return (height * 2).toInt().clamp(100, _maxImageHeight);
  }

  /// Get max disk cache width for image type
  int _getMaxDiskCacheWidth(ImageType imageType) {
    switch (imageType) {
      case ImageType.shop:
        return _maxImageWidth;
      case ImageType.profile:
        return 600;
      case ImageType.general:
        return 800;
    }
  }

  /// Get max disk cache height for image type
  int _getMaxDiskCacheHeight(ImageType imageType) {
    switch (imageType) {
      case ImageType.shop:
        return _maxImageHeight;
      case ImageType.profile:
        return 600;
      case ImageType.general:
        return 800;
    }
  }

  /// Estimate image size in bytes
  int _estimateImageSize(double? width, double? height) {
    final w = width?.toInt() ?? 400;
    final h = height?.toInt() ?? 400;
    // Rough estimate: width * height * 4 bytes per pixel (RGBA)
    return w * h * 4;
  }

  /// Build placeholder widget
  Widget _buildPlaceholder(Widget? placeholder, double? width, double? height) {
    if (placeholder != null) return placeholder;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(
    Widget? errorWidget,
    dynamic error,
    double? width,
    double? height,
  ) {
    if (errorWidget != null) return errorWidget;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Get cache statistics for a cache manager
  Future<CacheTypeStats> _getCacheStats(CacheManager cacheManager) async {
    try {
      // This is a simplified implementation
      // In a real app, you might need to access the cache's internal storage
      return const CacheTypeStats(entryCount: 0, totalSize: 0);
    } catch (e) {
      return const CacheTypeStats(entryCount: 0, totalSize: 0);
    }
  }

  /// Clear old cache entries
  Future<void> _clearOldCacheEntries(
    CacheManager cacheManager,
    Duration maxAge,
  ) async {
    // This would need to be implemented based on the specific cache manager's API
    // For now, we'll just clear the entire cache
    await cacheManager.emptyCache();
  }
}

// ============================================================================
// ENUMS AND DATA CLASSES
// ============================================================================

enum ImageType {
  shop, // Shop photos - highest priority, longest cache
  profile, // User profile images - medium priority
  general, // General images - lowest priority, shortest cache
}

class ImageCacheStatistics {
  final CacheTypeStats shopImages;
  final CacheTypeStats profileImages;
  final CacheTypeStats generalImages;
  final ImageCacheStats memoryStats;

  const ImageCacheStatistics({
    required this.shopImages,
    required this.profileImages,
    required this.generalImages,
    required this.memoryStats,
  });

  int get totalEntries =>
      shopImages.entryCount +
      profileImages.entryCount +
      generalImages.entryCount;
  int get totalSize =>
      shopImages.totalSize + profileImages.totalSize + generalImages.totalSize;
}

class CacheTypeStats {
  final int entryCount;
  final int totalSize;

  const CacheTypeStats({required this.entryCount, required this.totalSize});
}

// ============================================================================
// CONVENIENCE EXTENSIONS
// ============================================================================

extension OptimizedImageWidget on Widget {
  /// Wrap any widget with memory management
  Widget withMemoryManagement({
    String? key,
    MemoryPriority priority = MemoryPriority.normal,
  }) {
    return MemoryManagedWidget(memoryKey: key, priority: priority, child: this);
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Convenience function to get a cached image
Widget getCachedImage({
  required String imageUrl,
  ImageType imageType = ImageType.general,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
  MemoryPriority priority = MemoryPriority.normal,
  bool enableHeroAnimation = false,
  String? heroTag,
}) {
  return OptimizedImageCacheManager().getCachedImage(
    imageUrl: imageUrl,
    imageType: imageType,
    width: width,
    height: height,
    fit: fit,
    placeholder: placeholder,
    errorWidget: errorWidget,
    priority: priority,
    enableHeroAnimation: enableHeroAnimation,
    heroTag: heroTag,
  );
}

/// Convenience function to preload images
Future<void> preloadImages(
  List<String> imageUrls, {
  ImageType imageType = ImageType.general,
  MemoryPriority priority = MemoryPriority.normal,
}) {
  return OptimizedImageCacheManager().preloadImages(
    imageUrls,
    imageType: imageType,
    priority: priority,
  );
}
