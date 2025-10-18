import 'dart:async';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/user_service.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/services/forum_service.dart';
import 'package:wonwonw2/services/review_service.dart';
import 'package:wonwonw2/services/report_service.dart';
import 'package:wonwonw2/services/saved_shop_service.dart';
import 'package:wonwonw2/services/performance_monitor.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/advanced_search_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';

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

  // Service initialization status
  bool _isInitialized = false;
  final Set<String> _initializedServices = {};

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    appLog('ServiceManager: Initializing services...');

    try {
      // Initialize core services first
      await _initializeCoreServices();

      // Initialize feature services
      await _initializeFeatureServices();

      // Start monitoring services
      await _startMonitoringServices();

      _isInitialized = true;
      appLog('ServiceManager: All services initialized successfully');
    } catch (e) {
      appLog('ServiceManager: Failed to initialize services: $e');
      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    // Performance Monitor (highest priority)
    _performanceMonitor = PerformanceMonitor();
    _performanceMonitor!.startFrameMonitoring();
    _initializedServices.add('PerformanceMonitor');

    // Unified Memory Manager
    _memoryManager = UnifiedMemoryManager();
    await _memoryManager!.initialize();
    _initializedServices.add('UnifiedMemoryManager');

    // Optimized Image Cache Manager
    _imageCacheManager = OptimizedImageCacheManager();
    await _imageCacheManager!.initialize();
    _initializedServices.add('OptimizedImageCacheManager');

    // Advanced Search Service
    _advancedSearchService = AdvancedSearchService();
    await _advancedSearchService!.initialize();
    _initializedServices.add('AdvancedSearchService');

    // Auth Service (required by most other services)
    _authService = AuthService();
    _initializedServices.add('AuthService');

    appLog('ServiceManager: Core services initialized');
  }

  Future<void> _initializeFeatureServices() async {
    // User Service
    _userService = UserService();
    _initializedServices.add('UserService');

    // Shop Service
    _shopService = ShopService();
    _initializedServices.add('ShopService');

    // Forum Service
    _forumService = ForumService();
    _initializedServices.add('ForumService');

    // Review Service
    _reviewService = ReviewService();
    _initializedServices.add('ReviewService');

    // Report Service
    _reportService = ReportService();
    _initializedServices.add('ReportService');

    // Saved Shop Service
    _savedShopService = SavedShopService();
    _initializedServices.add('SavedShopService');

    appLog('ServiceManager: Feature services initialized');
  }

  Future<void> _startMonitoringServices() async {
    // Start performance monitoring for all services
    _performanceMonitor?.startOperation('service_manager_lifecycle');

    appLog('ServiceManager: Monitoring services started');
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

  /// Check if a specific service is initialized
  bool isServiceInitialized(String serviceName) {
    return _initializedServices.contains(serviceName);
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get list of initialized services
  List<String> get initializedServices => _initializedServices.toList();

  /// Dispose all services and clean up resources
  Future<void> dispose() async {
    appLog('ServiceManager: Disposing services...');

    try {
      // Stop monitoring services
      _performanceMonitor?.stopFrameMonitoring();
      _memoryManager?.dispose();

      // Dispose services in reverse order of initialization
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

      _initializedServices.clear();
      _isInitialized = false;

      appLog('ServiceManager: All services disposed successfully');
    } catch (e) {
      appLog('ServiceManager: Error disposing services: $e');
    }
  }

  /// Reset service manager (useful for testing)
  Future<void> reset() async {
    await dispose();
    await initialize();
  }

  /// Get service health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'initializedServices': _initializedServices.toList(),
      'serviceCount': _initializedServices.length,
      'memoryUsage': _memoryManager?.getObject('memory_usage'),
      'performanceMetrics': _performanceMonitor?.getPerformanceMetrics(),
    };
  }
}
