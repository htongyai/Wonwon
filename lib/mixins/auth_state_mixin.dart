import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/services/auth_manager.dart';
import 'package:wonwonw2/screens/login_screen.dart';

/// Mixin that provides consistent authentication state management
/// for all screens that need to track user login status
mixin AuthStateMixin<T extends StatefulWidget> on State<T> {
  final AuthManager _authManager = AuthManager();
  StreamSubscription<bool>? _authStateSubscription;
  StreamSubscription<User?>? _userSubscription;

  // Auth state variables
  bool _isLoggedIn = false;
  User? _currentUser;
  bool _isAuthLoading = true;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get isAuthLoading => _isAuthLoading;
  String? get currentUserId => _currentUser?.uid;
  String? get currentUserEmail => _currentUser?.email;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Initialize auth state and set up listeners
  void _initializeAuthState() {
    // Set initial state
    _isLoggedIn = _authManager.getIsLoggedIn();
    _currentUser = _authManager.currentUser;
    _isAuthLoading = false;

    // Listen for auth state changes
    _authStateSubscription = _authManager.authStateStream.listen((
      bool isLoggedIn,
    ) {
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isAuthLoading = false;
        });
        onAuthStateChanged(isLoggedIn);
      }
    });

    // Listen for user changes
    _userSubscription = _authManager.userStream.listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        onUserChanged(user);
      }
    });
  }

  /// Called when auth state changes (login/logout)
  /// Override this method in your widget to handle auth state changes
  void onAuthStateChanged(bool isLoggedIn) {
    // Override in your widget to handle auth state changes
  }

  /// Called when user data changes
  /// Override this method in your widget to handle user changes
  void onUserChanged(User? user) {
    // Override in your widget to handle user changes
  }

  /// Get current user name
  Future<String?> getCurrentUserName() async {
    return await _authManager.getCurrentUserName();
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    return await _authManager.isAdmin();
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    return await _authManager.login(email, password);
  }

  /// Logout user
  Future<void> logout() async {
    await _authManager.logout();
  }

  /// Register user
  Future<bool> register(
    String name,
    String email,
    String password,
    String accountType,
  ) async {
    return await _authManager.register(name, email, password, accountType);
  }

  /// Show login dialog when user needs to be authenticated
  Future<bool> showLoginDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    return result == true;
  }

  /// Handle authentication required actions
  Future<void> handleAuthRequiredAction(Function() action) async {
    if (_isLoggedIn) {
      action();
    } else {
      final loggedIn = await showLoginDialog();
      if (loggedIn && mounted) {
        action();
      }
    }
  }
}
