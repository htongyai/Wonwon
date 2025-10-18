import 'package:flutter/material.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';

/// Example screen showing how to use the new memory management system
class ExampleManagedScreen extends ManagedStatefulWidget {
  const ExampleManagedScreen({super.key});

  @override
  State<ExampleManagedScreen> createState() => _ExampleManagedScreenState();
}

class _ExampleManagedScreenState extends ManagedState<ExampleManagedScreen>
    with TickerProviderStateMixin {
  // Controllers are automatically managed by the mixin
  late final AnimationController _fadeController;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  // Data that should be cached
  List<String> _imageUrls = [];

  @override
  void onInitState() {
    // Create controllers using the mixin's convenience methods
    _fadeController = createAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    _searchController = createTextController();
    _scrollController = createScrollController();

    // Listen to streams with automatic cleanup
    listenToStream(_searchController.textChanged, (text) {
      _performSearch(text);
    });

    // Create timers with automatic cleanup
    createPeriodicTimer(const Duration(seconds: 30), (_) => _refreshData());

    // Register custom objects with memory management
    registerObject('screen_data', {
      'initialized_at': DateTime.now(),
    }, priority: MemoryPriority.high);

    // Start fade in animation
    _fadeController.forward();

    // Load initial data
    _loadInitialData();
  }

  @override
  void onDispose() {
    // Custom cleanup if needed
    // All controllers, subscriptions, and timers are automatically disposed
    // by the WidgetDisposalMixin
  }

  void _loadInitialData() {
    // Simulate loading image URLs
    _imageUrls = [
      'https://example.com/image1.jpg',
      'https://example.com/image2.jpg',
      'https://example.com/image3.jpg',
    ];

    // Preload images with priority
    preloadImages(
      _imageUrls,
      imageType: ImageType.shop,
      priority: MemoryPriority.high,
    );
  }

  void _performSearch(String query) {
    // Implement search logic
    // Results are automatically managed by the memory system
  }

  void _refreshData() {
    // Periodic data refresh
    // Old data is automatically cleaned up by the memory manager
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Managed Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.memory),
            onPressed: _showMemoryStats,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            // Search field with managed controller
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            // Image grid with optimized caching
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return _buildImageCard(_imageUrls[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, int index) {
    return getCachedImage(
      imageUrl: imageUrl,
      imageType: ImageType.shop,
      priority: MemoryPriority.normal,
      enableHeroAnimation: true,
      heroTag: 'image_$index',
      placeholder: const Center(child: CircularProgressIndicator()),
      errorWidget: const Center(child: Icon(Icons.error)),
    ).withMemoryManagement(
      key: 'image_card_$index',
      priority: MemoryPriority.normal,
    );
  }

  void _showMemoryStats() {
    final memoryManager = UnifiedMemoryManager();
    final stats = memoryManager.getMemoryStats();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Memory Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weak References: ${stats.weakReferences}'),
                Text('Active References: ${stats.activeReferences}'),
                Text('Widget States: ${stats.widgetStates}'),
                Text(
                  'Image Cache Entries: ${stats.imageCacheStats.totalEntries}',
                ),
                Text(
                  'Image Cache Size: ${_formatBytes(stats.imageCacheStats.totalSizeBytes)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  memoryManager.forceCleanup();
                  Navigator.of(context).pop();
                },
                child: const Text('Force Cleanup'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Extension to add text change stream to TextEditingController
extension TextControllerExtension on TextEditingController {
  Stream<String> get textChanged {
    return Stream.periodic(
      const Duration(milliseconds: 100),
    ).map((_) => text).distinct();
  }
}

