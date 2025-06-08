import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/services/memory_manager.dart';
import 'package:wonwonw2/services/widget_lifecycle_manager.dart';

class LazyLoadingImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final bool useMemoryCache;
  final String? memoryKey;
  final String? lifecycleKey;

  const LazyLoadingImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useMemoryCache = true,
    this.memoryKey,
    this.lifecycleKey,
  });

  @override
  State<LazyLoadingImage> createState() => _LazyLoadingImageState();
}

class _LazyLoadingImageState extends State<LazyLoadingImage> {
  final _performanceMonitor = PerformanceMonitor();
  final _memoryManager = MemoryManager();
  final _lifecycleManager = WidgetLifecycleManager();
  bool _isVisible = false;
  bool _isLoaded = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.lifecycleKey != null) {
      _lifecycleManager.onWidgetInit(widget.lifecycleKey!);
    }
    if (widget.memoryKey != null) {
      _memoryManager.registerObject(widget.memoryKey!, widget);
    }
  }

  @override
  void dispose() {
    if (widget.lifecycleKey != null) {
      _lifecycleManager.onWidgetDispose(widget.lifecycleKey!);
    }
    if (widget.memoryKey != null) {
      _memoryManager.unregisterObject(widget.memoryKey!);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyLoadingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lifecycleKey != null) {
      _lifecycleManager.onWidgetUpdate(widget.lifecycleKey!);
    }
    if (widget.imageUrl != oldWidget.imageUrl) {
      _isLoaded = false;
      _currentImageUrl = widget.imageUrl;
    }
  }

  void _onVisibilityChanged(bool isVisible) {
    if (isVisible != _isVisible) {
      setState(() {
        _isVisible = isVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lifecycleKey != null) {
      _lifecycleManager.onWidgetBuild(widget.lifecycleKey!);
    }

    final result = VisibilityDetector(
      key: Key('lazy_image_${widget.imageUrl}'),
      onVisibilityChanged:
          (info) => _onVisibilityChanged(info.visibleFraction > 0),
      child:
          _isVisible
              ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                fadeInDuration: widget.fadeInDuration,
                memCacheWidth: (widget.width ?? 800).toInt(),
                memCacheHeight: (widget.height ?? 800).toInt(),
                placeholder:
                    (context, url) =>
                        widget.placeholder ??
                        const Center(child: CircularProgressIndicator()),
                errorWidget:
                    (context, url, error) =>
                        widget.errorWidget ??
                        const Icon(Icons.error_outline, color: Colors.red),
                imageBuilder: (context, imageProvider) {
                  _isLoaded = true;
                  return Image(
                    image: imageProvider,
                    fit: widget.fit,
                    width: widget.width,
                    height: widget.height,
                  );
                },
              )
              : SizedBox(
                width: widget.width,
                height: widget.height,
                child:
                    widget.placeholder ??
                    const Center(child: CircularProgressIndicator()),
              ),
    );

    if (widget.lifecycleKey != null) {
      _lifecycleManager.onWidgetBuildComplete(widget.lifecycleKey!);
    }

    return result;
  }
}

class LazyLoadingImageList extends StatelessWidget {
  final List<String> imageUrls;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final bool useMemoryCache;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const LazyLoadingImageList({
    super.key,
    required this.imageUrls,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useMemoryCache = true,
    this.padding,
    this.physics,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return LazyLoadingImage(
          imageUrl: imageUrls[index],
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
          fadeInDuration: fadeInDuration,
          useMemoryCache: useMemoryCache,
          memoryKey: 'lazy_image_$index',
          lifecycleKey: 'lazy_image_$index',
        );
      },
    );
  }
}
