import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonwonw2/services/auth_service.dart';

/// Service to manage authentication state throughout the app
/// Allows users to access most app features without logging in
class AuthStateService {
  // Keys for shared preferences
  static const String _hasSeenIntroKey = 'has_seen_intro';
  static const String _isGuestModeKey = 'is_guest_mode';

  // Authentication service
  final AuthService _authService = AuthService();

  // Auth state variables
  bool _isLoggedIn = false;
  bool _isGuestMode = true;
  bool _hasSeenIntro = false;

  // Auth state controller
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  // Singleton pattern
  static final AuthStateService _instance = AuthStateService._internal();
  factory AuthStateService() => _instance;
  AuthStateService._internal();

  // Stream of auth state changes
  Stream<AuthState> get authStateStream => _authStateController.stream;

  // Current auth state getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  bool get hasSeenIntro => _hasSeenIntro;

  // Initialize auth state
  Future<void> initialize() async {
    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _hasSeenIntro = prefs.getBool(_hasSeenIntroKey) ?? false;

    // Always enable guest mode by default (automatically allow using the app without login)
    _isGuestMode = true;
    await prefs.setBool(_isGuestModeKey, true);

    // Check login status
    _isLoggedIn = await _authService.isLoggedIn();

    // Set up Firebase Auth state listener
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _isLoggedIn = user != null;
      _notifyAuthStateChange();
    });

    // Notify initial state
    _notifyAuthStateChange();
  }

  // Notify listeners of auth state change
  void _notifyAuthStateChange() {
    _authStateController.add(
      AuthState(
        isLoggedIn: _isLoggedIn,
        isGuestMode: _isGuestMode,
        hasSeenIntro: _hasSeenIntro,
      ),
    );
  }

  // Set intro seen status
  Future<void> setIntroSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenIntroKey, seen);
    _hasSeenIntro = seen;
    _notifyAuthStateChange();
  }

  // Enable guest mode
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestModeKey, true);
    _isGuestMode = true;
    _notifyAuthStateChange();
  }

  // Disable guest mode (require login)
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestModeKey, false);
    _isGuestMode = false;
    _notifyAuthStateChange();
  }

  // Check if a feature requires authentication
  bool canAccessFeature(FeatureAccess featureAccess) {
    switch (featureAccess) {
      case FeatureAccess.public:
        return true;
      case FeatureAccess.preferLoggedIn:
        return _isLoggedIn || _isGuestMode;
      case FeatureAccess.requiresLogin:
        return _isLoggedIn;
    }
  }

  // Dispose resources
  void dispose() {
    _authStateController.close();
  }
}

/// Represents the current authentication state of the app
class AuthState {
  final bool isLoggedIn;
  final bool isGuestMode;
  final bool hasSeenIntro;

  AuthState({
    required this.isLoggedIn,
    required this.isGuestMode,
    required this.hasSeenIntro,
  });
}

/// Enum representing different levels of feature access requirements
enum FeatureAccess {
  // Features available to all users
  public,
  // Features that prefer logged-in users but allow guest access
  preferLoggedIn,
  // Features that strictly require login
  requiresLogin,
}
