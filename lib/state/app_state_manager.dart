import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wonwonw2/models/user.dart' as app_user;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:wonwonw2/services/user_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';

/// Centralized state management for the application
class AppStateManager extends ChangeNotifier {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  final ServiceManager _serviceManager = ServiceManager();

  // Authentication state
  app_user.User? _currentUser;
  firebase_auth.User? _firebaseUser;
  bool _isAuthenticated = false;
  bool _isAuthLoading = false;

  // App state
  bool _isLoading = false;
  String? _error;
  String _currentLanguage = 'en';
  bool _isDarkMode = false;

  // Data state
  List<RepairShop> _shops = [];
  List<RepairShop> _savedShops = [];
  List<RepairShop> _filteredShops = [];
  String _searchQuery = '';
  String? _selectedCategory;

  // Subscriptions for real-time updates
  StreamSubscription? _userSubscription;
  StreamSubscription? _shopsSubscription;

  // Getters
  app_user.User? get currentUser => _currentUser;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthLoading => _isAuthLoading;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentLanguage => _currentLanguage;
  bool get isDarkMode => _isDarkMode;
  List<RepairShop> get shops => _shops;
  List<RepairShop> get savedShops => _savedShops;
  List<RepairShop> get filteredShops => _filteredShops;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  /// Initialize the state manager
  Future<void> initialize() async {
    appLog('AppStateManager: Initializing...');

    try {
      setLoading(true);

      // Initialize services
      await _serviceManager.initialize();

      // Check authentication state
      await _checkAuthState();

      // Load initial data
      await _loadInitialData();

      // Set up real-time listeners
      _setupRealtimeListeners();

      setLoading(false);
      appLog('AppStateManager: Initialized successfully');
    } catch (e) {
      setError('Failed to initialize app: $e');
      appLog('AppStateManager: Initialization failed: $e');
    }
  }

  /// Check current authentication state
  Future<void> _checkAuthState() async {
    try {
      _isAuthLoading = true;
      notifyListeners();

      _firebaseUser = _serviceManager.authService.currentUser;
      _isAuthenticated = _firebaseUser != null;

      // If user is authenticated, get full user data
      if (_firebaseUser != null) {
        try {
          _currentUser = await UserService.getCurrentUser();
        } catch (e) {
          appLog('AppStateManager: Failed to get user data: $e');
        }
      } else {
        _currentUser = null;
      }

      _isAuthLoading = false;
      notifyListeners();
      appLog(
        'AppStateManager: Auth state checked - authenticated: $_isAuthenticated',
      );
    } catch (e) {
      _isAuthLoading = false;
      appLog('AppStateManager: Auth state check failed: $e');
      notifyListeners();
    }
  }

  /// Load initial data
  Future<void> _loadInitialData() async {
    if (!_isAuthenticated) return;

    try {
      // Load shops
      final shops = await _serviceManager.shopService.getAllShops();
      _shops = shops;
      _filteredShops = shops;

      // Load saved shops if user is authenticated
      if (_firebaseUser != null) {
        final savedShopIds =
            await _serviceManager.savedShopService.getSavedShopIds();
        _savedShops =
            _shops.where((shop) => savedShopIds.contains(shop.id)).toList();
      }

      notifyListeners();
      appLog('AppStateManager: Initial data loaded');
    } catch (e) {
      setError('Failed to load initial data: $e');
    }
  }

  /// Set up real-time listeners
  void _setupRealtimeListeners() {
    // Listen to Firebase auth changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      _firebaseUser = user;
      _isAuthenticated = user != null;

      if (user == null) {
        _currentUser = null;
        _savedShops.clear();
      }

      notifyListeners();
    });

    // Listen to shops changes (simplified - using periodic refresh for now)
    Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isAuthenticated) {
        _loadInitialData();
      }
    });
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    try {
      _isAuthLoading = true;
      notifyListeners();

      final result = await _serviceManager.authService.login(email, password);

      if (result.success) {
        await _checkAuthState();
        await _loadInitialData();
      }

      _isAuthLoading = false;
      notifyListeners();

      return result.success;
    } catch (e) {
      _isAuthLoading = false;
      setError('Login failed: $e');
      return false;
    }
  }

  /// Register user
  Future<bool> register(
    String name,
    String email,
    String password,
    String accountType,
  ) async {
    try {
      _isAuthLoading = true;
      notifyListeners();

      final success = await _serviceManager.authService.register(
        name,
        email,
        password,
        accountType,
      );

      if (success) {
        await _checkAuthState();
        await _loadInitialData();
        _setupRealtimeListeners();
      }

      _isAuthLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isAuthLoading = false;
      setError('Registration failed: $e');
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _serviceManager.authService.logout();

      // Clear state
      _currentUser = null;
      _isAuthenticated = false;
      _shops.clear();
      _savedShops.clear();
      _filteredShops.clear();

      // Cancel subscriptions
      await _userSubscription?.cancel();
      await _shopsSubscription?.cancel();
      _userSubscription = null;
      _shopsSubscription = null;

      notifyListeners();
      appLog('AppStateManager: User logged out');
    } catch (e) {
      setError('Logout failed: $e');
    }
  }

  /// Search shops
  void searchShops(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter shops by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Apply search and category filters
  void _applyFilters() {
    _filteredShops =
        _shops.where((shop) {
          // Category filter
          if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
            if (!shop.categories.contains(_selectedCategory)) {
              return false;
            }
          }

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return shop.name.toLowerCase().contains(query) ||
                shop.address.toLowerCase().contains(query) ||
                shop.categories.any((cat) => cat.toLowerCase().contains(query));
          }

          return true;
        }).toList();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _filteredShops = _shops;
    notifyListeners();
  }

  /// Save/unsave shop
  Future<void> toggleSaveShop(String shopId) async {
    if (_firebaseUser == null) return;

    try {
      final isSaved = _savedShops.any((shop) => shop.id == shopId);

      if (isSaved) {
        await _serviceManager.savedShopService.removeShop(shopId);
        _savedShops.removeWhere((shop) => shop.id == shopId);
      } else {
        await _serviceManager.savedShopService.saveShop(shopId);
        final shop = _shops.firstWhere((s) => s.id == shopId);
        _savedShops.add(shop);
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to save/unsave shop: $e');
    }
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  /// Set error state
  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
    appLog('AppStateManager: Error set: $error');
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Change language
  void changeLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
    appLog('AppStateManager: Language changed to: $languageCode');
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    appLog('AppStateManager: Dark mode toggled: $_isDarkMode');
  }

  /// Refresh data
  Future<void> refresh() async {
    try {
      setLoading(true);
      await _loadInitialData();
      setLoading(false);
    } catch (e) {
      setError('Failed to refresh data: $e');
    }
  }

  /// Check if shop is saved
  bool isShopSaved(String shopId) {
    return _savedShops.any((shop) => shop.id == shopId);
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return _serviceManager.performanceMonitor.getPerformanceMetrics();
  }

  /// Dispose resources
  @override
  void dispose() {
    _userSubscription?.cancel();
    _shopsSubscription?.cancel();
    _serviceManager.dispose();
    super.dispose();
  }
}
