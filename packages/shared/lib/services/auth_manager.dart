import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/utils/app_logger.dart';

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

  /// Login user. Returns true on success, rethrows on failure so the
  /// caller can show an appropriate error message.
  Future<bool> login(String email, String password) async {
    final result = await _authService.login(email, password);
    return result.success;
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
  }

  /// Register user
  Future<RegistrationResult> register(
    String name,
    String email,
    String password,
    String accountType, {
    bool acceptedTerms = false,
  }) async {
    try {
      return await _authService.register(
        name, email, password, accountType,
        acceptedTerms: acceptedTerms,
      );
    } catch (e) {
      return RegistrationResult(
        success: false,
        errorType: RegistrationErrorType.unknown,
        errorKey: 'unexpected_error',
      );
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
        await _currentUser!.getIdToken(true);
        appLog('AuthManager: Token refreshed');
      } catch (e) {
        appLog('AuthManager: Token refresh failed: $e');
        // If token refresh fails, the user needs to re-login
        await _handleTokenRefreshFailure(e);
      }
    }
  }

  /// Handle token refresh failure
  Future<void> _handleTokenRefreshFailure(dynamic error) async {
    appLog('AuthManager: Handling token refresh failure: $error');

    try {
      await logout();
    } catch (logoutError) {
      appLog('AuthManager: Error during logout after token failure: $logoutError');
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
      appLog('AuthManager: Token validation failed: $e');
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
