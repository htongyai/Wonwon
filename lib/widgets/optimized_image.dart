import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/config/web_config.dart';

/// Optimized image widget with caching, lazy loading, and error handling
class OptimizedImage extends StatefulWidget {
  final String? imageUrl;
  final String? assetPath;
  final Uint8List? imageData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final Duration cacheDuration;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool fadeInAnimation;
  final Duration fadeInDuration;
  final String? heroTag;

  const OptimizedImage({
    Key? key,
    this.imageUrl,
    this.assetPath,
    this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.cacheDuration = const Duration(hours: 24),
    this.borderRadius,
    this.backgroundColor,
    this.fadeInAnimation = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.heroTag,
  }) : assert(
         imageUrl != null || assetPath != null || imageData != null,
         'At least one image source must be provided',
       ),
       super(key: key);

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    if (widget.fadeInAnimation) {
      _animationController = AnimationController(
        duration: widget.fadeInDuration,
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
      );
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Widget get _defaultPlaceholder {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor ?? Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget get _defaultErrorWidget {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor ?? Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    Widget imageWidget;

    if (widget.imageData != null) {
      // Memory image
      imageWidget = Image.memory(
        widget.imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          appLog('OptimizedImage: Memory image error: $error');
          return widget.errorWidget ?? _defaultErrorWidget;
        },
      );
    } else if (widget.assetPath != null) {
      // Asset image
      imageWidget = Image.asset(
        widget.assetPath!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          appLog('OptimizedImage: Asset image error: $error');
          return widget.errorWidget ?? _defaultErrorWidget;
        },
      );
    } else if (widget.imageUrl != null) {
      // Network image with caching
      final optimizedUrl =
          kIsWeb
              ? WebUtils.optimizeImageUrl(
                widget.imageUrl!,
                width: widget.width?.toInt(),
                height: widget.height?.toInt(),
              )
              : widget.imageUrl!;

      imageWidget = CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
        placeholder: (context, url) {
          return widget.placeholder ?? _defaultPlaceholder;
        },
        errorWidget: (context, url, error) {
          appLog('OptimizedImage: Network image error: $error');
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          return widget.errorWidget ?? _defaultErrorWidget;
        },
        imageBuilder: (context, imageProvider) {
          setState(() {
            _isLoading = false;
            _hasError = false;
          });

          if (widget.fadeInAnimation && _animationController != null) {
            _animationController!.forward();
          }

          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
        cacheManager:
            widget.enableDiskCache ? null : null, // Use default cache manager
      );
    } else {
      imageWidget = widget.errorWidget ?? _defaultErrorWidget;
    }

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    // Apply fade animation if enabled
    if (widget.fadeInAnimation &&
        _fadeAnimation != null &&
        !_isLoading &&
        !_hasError) {
      imageWidget = FadeTransition(
        opacity: _fadeAnimation!,
        child: imageWidget,
      );
    }

    // Apply hero animation if specified
    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: imageWidget);
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildImageWidget();
  }
}

/// Optimized circular image widget
class OptimizedCircularImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final Uint8List? imageData;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const OptimizedCircularImage({
    Key? key,
    this.imageUrl,
    this.assetPath,
    this.imageData,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border:
            borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor!, width: borderWidth)
                : null,
      ),
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl,
          assetPath: assetPath,
          imageData: imageData,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder:
              placeholder ??
              Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: radius,
                  color: Colors.grey[400],
                ),
              ),
          errorWidget:
              errorWidget ??
              Container(
                color: Colors.grey[100],
                child: Icon(
                  Icons.person,
                  size: radius,
                  color: Colors.grey[400],
                ),
              ),
        ),
      ),
    );
  }
}

/// Optimized image gallery widget
class OptimizedImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double aspectRatio;
  final bool enableZoom;
  final bool enableSwipe;
  final int initialIndex;
  final void Function(int index)? onPageChanged;

  const OptimizedImageGallery({
    Key? key,
    required this.imageUrls,
    this.aspectRatio = 16 / 9,
    this.enableZoom = true,
    this.enableSwipe = true,
    this.initialIndex = 0,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<OptimizedImageGallery> createState() => _OptimizedImageGalleryState();
}

class _OptimizedImageGalleryState extends State<OptimizedImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return OptimizedImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
                heroTag: 'gallery_image_$index',
              );
            },
          ),
        ),

        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      index == _currentIndex
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
