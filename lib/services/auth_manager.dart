import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/services/auth_service.dart';

/// Centralized authentication manager that provides consistent auth state
/// across the entire application
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final AuthService _authService = AuthService();
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();

  User? _currentUser;
  bool _isLoggedIn = false;
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _tokenRefreshTimer;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  Stream<bool> get authStateStream => _authStateController.stream;
  Stream<User?> get userStream => _userController.stream;

  /// Initialize the auth manager
  Future<void> initialize() async {
    // Set up Firebase auth state listener
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      _currentUser = user;
      _isLoggedIn = user != null;

      // Notify listeners
      _authStateController.add(_isLoggedIn);
      _userController.add(_currentUser);

      // Set up token refresh if user is logged in
      if (user != null) {
        _startTokenRefreshTimer();
      } else {
        _stopTokenRefreshTimer();
      }
    });

    // Set initial state
    _currentUser = FirebaseAuth.instance.currentUser;
    _isLoggedIn = _currentUser != null;
    _authStateController.add(_isLoggedIn);
    _userController.add(_currentUser);

    // Start token refresh if user is already logged in
    if (_isLoggedIn) {
      _startTokenRefreshTimer();
    }
  }

  /// Check if user is logged in (synchronous)
  bool getIsLoggedIn() {
    return _isLoggedIn;
  }

  /// Check if user is logged in (asynchronous - for compatibility)
  Future<bool> isLoggedInAsync() async {
    return _isLoggedIn;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _currentUser?.uid;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _currentUser?.email;
  }

  /// Get current user name
  Future<String?> getCurrentUserName() async {
    return await _authService.getUserName();
  }

  /// Login user with retry mechanism
  Future<bool> login(String email, String password) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final result = await _authService.login(email, password);
        if (result.success) {
          return true;
        }

        // If login failed, wait before retrying
        if (retryCount < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        }
      } catch (e) {
        print('AuthManager: Login attempt ${retryCount + 1} failed: $e');
        if (retryCount < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        }
      }

      retryCount++;
    }

    return false;
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Register user
  Future<bool> register(
    String name,
    String email,
    String password,
    String accountType,
  ) async {
    try {
      return await _authService.register(name, email, password, accountType);
    } catch (e) {
      return false;
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    return await _authService.isAdmin();
  }

  /// Start token refresh timer
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer(); // Stop any existing timer

    // Refresh token every 45 minutes (Firebase tokens expire after 1 hour)
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) {
      _refreshTokenIfNeeded();
    });
  }

  /// Stop token refresh timer
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Refresh token if needed
  Future<void> _refreshTokenIfNeeded() async {
    if (_currentUser != null) {
      try {
        // Force refresh the token
        await _currentUser!.getIdToken(true);
        print('AuthManager: Token refreshed successfully');
      } catch (e) {
        print('AuthManager: Token refresh failed: $e');
        // If token refresh fails, the user needs to re-login
        await _handleTokenRefreshFailure(e);
      }
    }
  }

  /// Handle token refresh failure
  Future<void> _handleTokenRefreshFailure(dynamic error) async {
    print('AuthManager: Handling token refresh failure: $error');

    // Try to logout gracefully
    try {
      await logout();
    } catch (logoutError) {
      print(
        'AuthManager: Error during logout after token failure: $logoutError',
      );
    }

    // Notify listeners that auth state has changed
    _authStateController.add(false);
    _userController.add(null);
  }

  /// Validate current token
  Future<bool> validateToken() async {
    if (_currentUser == null) return false;

    try {
      await _currentUser!.getIdToken(true);
      return true;
    } catch (e) {
      print('AuthManager: Token validation failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
    _stopTokenRefreshTimer();
    _authStateController.close();
    _userController.close();
  }
}
