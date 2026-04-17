import 'dart:async';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/user_service.dart';
import 'package:shared/services/shop_service.dart';
import 'package:shared/services/forum_service.dart';
import 'package:shared/services/review_service.dart';
import 'package:shared/services/report_service.dart';
import 'package:shared/services/saved_shop_service.dart';
import 'package:shared/services/performance_monitor.dart';
import 'package:shared/services/unified_memory_manager.dart';
import 'package:shared/services/optimized_image_cache_manager.dart';
import 'package:shared/services/advanced_search_service.dart';
import 'package:shared/utils/app_logger.dart';

/// Centralized service manager for dependency injection and lifecycle management
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  // Service instances
  AuthService? _authService;
  UserService? _userService;
  ShopService? _shopService;
  ForumService? _forumService;
  ReviewService? _reviewService;
  ReportService? _reportService;
  SavedShopService? _savedShopService;
  PerformanceMonitor? _performanceMonitor;
  UnifiedMemoryManager? _memoryManager;
  OptimizedImageCacheManager? _imageCacheManager;
  AdvancedSearchService? _advancedSearchService;

  bool _isInitialized = false;

  /// Initialize all services. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isInitialized) return;

    appLog('ServiceManager: Initializing services...');

    try {
      // Core infrastructure
      _performanceMonitor = PerformanceMonitor()..startFrameMonitoring();
      _memoryManager = UnifiedMemoryManager();
      _imageCacheManager = OptimizedImageCacheManager();
      _advancedSearchService = AdvancedSearchService();
      _authService = AuthService();

      await Future.wait([
        _memoryManager!.initialize(),
        _imageCacheManager!.initialize(),
        _advancedSearchService!.initialize(),
      ]);

      // Feature services (no async init needed)
      _userService = UserService();
      _shopService = ShopService();
      _forumService = ForumService();
      _reviewService = ReviewService();
      _reportService = ReportService();
      _savedShopService = SavedShopService();

      _isInitialized = true;
      appLog('ServiceManager: All services initialized');
    } catch (e) {
      appLog('ServiceManager: Failed to initialize services: $e');
      rethrow;
    }
  }

  /// Get service instances with lazy initialization
  AuthService get authService {
    _authService ??= AuthService();
    return _authService!;
  }

  UserService get userService {
    _userService ??= UserService();
    return _userService!;
  }

  ShopService get shopService {
    _shopService ??= ShopService();
    return _shopService!;
  }

  ForumService get forumService {
    _forumService ??= ForumService();
    return _forumService!;
  }

  ReviewService get reviewService {
    _reviewService ??= ReviewService();
    return _reviewService!;
  }

  ReportService get reportService {
    _reportService ??= ReportService();
    return _reportService!;
  }

  SavedShopService get savedShopService {
    _savedShopService ??= SavedShopService();
    return _savedShopService!;
  }

  PerformanceMonitor get performanceMonitor {
    _performanceMonitor ??= PerformanceMonitor();
    return _performanceMonitor!;
  }

  UnifiedMemoryManager get memoryManager {
    _memoryManager ??= UnifiedMemoryManager();
    return _memoryManager!;
  }

  OptimizedImageCacheManager get imageCacheManager {
    _imageCacheManager ??= OptimizedImageCacheManager();
    return _imageCacheManager!;
  }

  AdvancedSearchService get advancedSearchService {
    _advancedSearchService ??= AdvancedSearchService();
    return _advancedSearchService!;
  }

  bool get isInitialized => _isInitialized;

  /// Dispose all services and clean up resources.
  Future<void> dispose() async {
    appLog('ServiceManager: Disposing services...');

    try {
      _performanceMonitor?.stopFrameMonitoring();
      _memoryManager?.dispose();

      _savedShopService = null;
      _reportService = null;
      _reviewService = null;
      _forumService = null;
      _shopService = null;
      _userService = null;
      _authService = null;
      _imageCacheManager = null;
      _advancedSearchService = null;
      _memoryManager = null;
      _performanceMonitor = null;
      _isInitialized = false;

      appLog('ServiceManager: All services disposed');
    } catch (e) {
      appLog('ServiceManager: Error disposing services: $e');
    }
  }

  /// Get service health status.
  Map<String, dynamic> getHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'memoryUsage': _memoryManager?.getObject('memory_usage'),
      'performanceMetrics': _performanceMonitor?.getPerformanceMetrics(),
    };
  }
}
