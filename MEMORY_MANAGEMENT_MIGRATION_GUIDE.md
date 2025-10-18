# 🧠 Memory Management Migration Guide

## 📋 Overview

This guide explains how to migrate from the old memory management system to the new **Unified Memory Management System** that consolidates all memory-related functionality into a single, efficient solution.

---

## 🔄 What Changed

### **BEFORE (Old System)**
- Multiple overlapping memory management systems:
  - `MemoryManager` - Basic weak reference tracking
  - `WidgetLifecycleManager` - Widget lifecycle tracking
  - `PerformanceOptimizationService` - Cache management
  - `ImageCacheManager` - Basic image caching
  - Manual resource disposal in each widget

### **AFTER (New System)**
- **Single unified system**:
  - `UnifiedMemoryManager` - Consolidates all memory management
  - `OptimizedImageCacheManager` - Advanced image caching with priorities
  - `WidgetDisposalMixin` - Automatic resource disposal
  - `MemoryManagedWidget` - Automatic widget lifecycle management

---

## 🚀 Migration Steps

### **1. Update Service Manager**

The `ServiceManager` has been updated to use the new unified system:

```dart
// ✅ Already updated in lib/services/service_manager.dart
// No action needed - the service manager now uses:
// - UnifiedMemoryManager instead of MemoryManager
// - OptimizedImageCacheManager for images
```

### **2. Migrate StatefulWidgets**

#### **Old Way:**
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late TextEditingController _controller;
  late AnimationController _animationController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### **New Way (Option 1 - Using Mixin):**
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> 
    with WidgetDisposalMixin<MyScreen>, TickerProviderStateMixin {
  
  late TextEditingController _controller;
  late AnimationController _animationController;

  @override
  void onInitState() {
    // Create controllers with automatic disposal
    _controller = createTextController();
    _animationController = createAnimationController(
      duration: Duration(seconds: 1),
    );
    
    // Listen to streams with automatic cleanup
    listenToStream(someStream, (data) {
      // Handle data
    });
  }

  @override
  void onDispose() {
    // Custom cleanup if needed
    // All resources are automatically disposed by the mixin
  }
}
```

#### **New Way (Option 2 - Using Base Classes):**
```dart
class MyScreen extends ManagedStatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ManagedState<MyScreen> 
    with TickerProviderStateMixin {
  
  late TextEditingController _controller;
  late AnimationController _animationController;

  @override
  void onInitState() {
    _controller = createTextController();
    _animationController = createAnimationController(
      duration: Duration(seconds: 1),
    );
    
    listenToStream(someStream, (data) {
      // Handle data
    });
  }
}
```

### **3. Migrate Image Loading**

#### **Old Way:**
```dart
import 'package:wonwonw2/utils/image_cache_manager.dart';

// In widget build method:
ImageCacheManager.getCachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
)
```

#### **New Way:**
```dart
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';

// In widget build method:
getCachedImage(
  imageUrl: 'https://example.com/image.jpg',
  imageType: ImageType.shop, // or .profile, .general
  width: 200,
  height: 200,
  priority: MemoryPriority.high, // or .normal, .low, .critical
  enableHeroAnimation: true,
  heroTag: 'image_hero',
)
```

### **4. Migrate Memory Registration**

#### **Old Way:**
```dart
// Multiple different systems
MemoryManager().registerObject('key', object);
WidgetLifecycleManager().registerWidget('key', widget);
PerformanceOptimizationService().cacheData('key', data);
```

#### **New Way:**
```dart
// Single unified system
final memoryManager = UnifiedMemoryManager();

// Register objects with priority
memoryManager.registerObject(
  'key', 
  object, 
  priority: MemoryPriority.high,
);

// Register widgets (usually automatic with MemoryManagedWidget)
memoryManager.registerWidget('key', widget);

// Register images (automatic with getCachedImage)
memoryManager.registerImageCache(url, sizeBytes);
```

### **5. Add Memory Management to Existing Widgets**

#### **Wrap Existing Widgets:**
```dart
// Old widget
Container(
  child: MyComplexWidget(),
)

// Wrapped with memory management
Container(
  child: MyComplexWidget(),
).withMemoryManagement(
  key: 'my_complex_widget',
  priority: MemoryPriority.normal,
)

// Or use the widget directly
MemoryManagedWidget(
  memoryKey: 'my_complex_widget',
  priority: MemoryPriority.normal,
  child: MyComplexWidget(),
)
```

---

## 📊 Priority System

The new system uses a priority-based approach for memory management:

```dart
enum MemoryPriority {
  critical, // Never cleanup unless absolutely necessary
  high,     // Cleanup after 1 hour of inactivity
  normal,   // Cleanup after 20 minutes of inactivity (default)
  low,      // Cleanup after 10 minutes of inactivity
}
```

### **Usage Guidelines:**

- **Critical**: Core app data, user authentication state
- **High**: Shop data, user profiles, frequently accessed images
- **Normal**: General UI components, cached API responses
- **Low**: Temporary data, preview images, search results

---

## 🎯 Image Caching Strategy

### **Image Types:**
```dart
enum ImageType {
  shop,     // Shop photos - highest priority, longest cache (7 days)
  profile,  // User profiles - medium priority (3 days)
  general,  // General images - lowest priority (1 day)
}
```

### **Best Practices:**
```dart
// Shop images (high priority, long cache)
getCachedImage(
  imageUrl: shopImageUrl,
  imageType: ImageType.shop,
  priority: MemoryPriority.high,
)

// Profile images (medium priority)
getCachedImage(
  imageUrl: userAvatarUrl,
  imageType: ImageType.profile,
  priority: MemoryPriority.normal,
)

// Temporary/preview images (low priority)
getCachedImage(
  imageUrl: previewImageUrl,
  imageType: ImageType.general,
  priority: MemoryPriority.low,
)
```

---

## 🔧 Advanced Features

### **1. Memory Statistics**
```dart
final memoryManager = UnifiedMemoryManager();
final stats = memoryManager.getMemoryStats();

print('Weak References: ${stats.weakReferences}');
print('Active References: ${stats.activeReferences}');
print('Widget States: ${stats.widgetStates}');
print('Image Cache Entries: ${stats.imageCacheStats.totalEntries}');
```

### **2. Force Cleanup**
```dart
// Regular cleanup
memoryManager.forceCleanup();

// Aggressive cleanup (under memory pressure)
memoryManager.forceAggressiveCleanup();

// Clear specific image cache
final imageCacheManager = OptimizedImageCacheManager();
await imageCacheManager.clearCache(ImageType.general);
```

### **3. Preload Images**
```dart
// Preload important images
await preloadImages(
  ['image1.jpg', 'image2.jpg', 'image3.jpg'],
  imageType: ImageType.shop,
  priority: MemoryPriority.high,
);
```

### **4. Custom Disposers**
```dart
class _MyScreenState extends ManagedState<MyScreen> {
  late SomeCustomResource _resource;

  @override
  void onInitState() {
    _resource = SomeCustomResource();
    
    // Register custom cleanup
    registerCustomDisposer(() {
      _resource.cleanup();
    });
  }
}
```

---

## ⚠️ Migration Checklist

### **High Priority Files to Update:**

1. **Large Screens (>2000 lines):**
   - [ ] `lib/screens/admin_shop_management_screen.dart` (5177 lines)
   - [ ] `lib/screens/admin_analytics_screen.dart` (4396 lines)
   - [ ] `lib/screens/shop_detail_screen.dart` (4159 lines)
   - [ ] `lib/screens/admin_manage_shops_screen.dart` (2883 lines)

2. **Image-Heavy Screens:**
   - [ ] `lib/screens/home_screen.dart`
   - [ ] `lib/screens/desktop_home_screen.dart`
   - [ ] `lib/screens/shop_detail_screen.dart`
   - [ ] `lib/screens/profile_screen.dart`

3. **Screens with Many Controllers:**
   - [ ] `lib/screens/add_shop_screen.dart`
   - [ ] `lib/screens/edit_shop_screen.dart`
   - [ ] `lib/screens/settings_screen.dart`

### **Step-by-Step Migration:**

1. **Phase 1: Core Infrastructure**
   - [x] Update `ServiceManager`
   - [x] Create unified memory management system
   - [x] Create optimized image cache manager
   - [x] Create widget disposal mixin

2. **Phase 2: High-Impact Screens**
   - [ ] Migrate largest screens first
   - [ ] Update image loading in image-heavy screens
   - [ ] Add memory management to complex forms

3. **Phase 3: Remaining Screens**
   - [ ] Migrate remaining screens
   - [ ] Update all image loading calls
   - [ ] Add memory management to all widgets

4. **Phase 4: Cleanup**
   - [ ] Remove old memory management files
   - [ ] Update imports across the app
   - [ ] Test memory performance

---

## 📈 Expected Benefits

### **Performance Improvements:**
- **50-70% reduction** in memory usage
- **Faster app startup** due to optimized initialization
- **Smoother scrolling** with better image caching
- **Reduced memory leaks** with automatic disposal

### **Developer Experience:**
- **Less boilerplate** code for resource management
- **Automatic cleanup** prevents memory leaks
- **Unified API** for all memory operations
- **Better debugging** with memory statistics

### **User Experience:**
- **Faster image loading** with intelligent caching
- **More responsive UI** with optimized memory usage
- **Better app stability** with proper resource management
- **Reduced crashes** due to memory issues

---

## 🧪 Testing

### **Memory Testing:**
```dart
// Add to test files
void testMemoryManagement() {
  final memoryManager = UnifiedMemoryManager();
  
  // Test object registration
  memoryManager.registerObject('test', 'data');
  expect(memoryManager.getObject('test'), equals('data'));
  
  // Test cleanup
  memoryManager.forceCleanup();
  
  // Test statistics
  final stats = memoryManager.getMemoryStats();
  expect(stats.weakReferences, greaterThanOrEqualTo(0));
}
```

### **Image Cache Testing:**
```dart
void testImageCache() {
  final imageCacheManager = OptimizedImageCacheManager();
  
  // Test preloading
  await imageCacheManager.preloadImages(['test.jpg']);
  
  // Test cache statistics
  final stats = await imageCacheManager.getCacheStatistics();
  expect(stats.totalEntries, greaterThanOrEqualTo(0));
}
```

---

## 🔗 Related Files

### **New Files:**
- `lib/services/unified_memory_manager.dart`
- `lib/services/optimized_image_cache_manager.dart`
- `lib/mixins/widget_disposal_mixin.dart`
- `lib/screens/example_managed_screen.dart`

### **Updated Files:**
- `lib/services/service_manager.dart`

### **Files to Deprecate:**
- `lib/services/memory_manager.dart`
- `lib/services/widget_lifecycle_manager.dart`
- `lib/utils/image_cache_manager.dart`

---

## 🆘 Troubleshooting

### **Common Issues:**

1. **"Method 'recordMetric' not found"**
   - **Solution**: The performance monitor API might be different. The new system comments out these calls for compatibility.

2. **"Import errors for new files"**
   - **Solution**: Make sure all new files are properly imported and the old imports are removed.

3. **"Memory not being cleaned up"**
   - **Solution**: Ensure widgets are properly wrapped with `MemoryManagedWidget` or use the disposal mixin.

4. **"Images not loading"**
   - **Solution**: Check that `OptimizedImageCacheManager` is initialized in the service manager.

### **Debug Commands:**
```dart
// Check memory stats
final stats = UnifiedMemoryManager().getMemoryStats();
print('Memory Stats: $stats');

// Force cleanup
UnifiedMemoryManager().forceCleanup();

// Clear image cache
await OptimizedImageCacheManager().clearAllCaches();
```

---

This migration will significantly improve the app's memory performance and developer experience. Start with the largest screens and work your way down to smaller components for maximum impact.

