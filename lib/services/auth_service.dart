import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:wonwonw2/services/activity_service.dart';

// Password strength enum
enum PasswordStrength { none, weak, fair, good, strong }

// Password validation result
class PasswordValidationResult {
  final bool isValid;
  final String message;
  final PasswordStrength strength;

  PasswordValidationResult({
    required this.isValid,
    required this.message,
    required this.strength,
  });
}

// Login error types
enum LoginErrorType {
  invalidEmail,
  userNotFound,
  wrongPassword,
  userDisabled,
  tooManyRequests,
  accountLocked,
  unknown,
}

// Login result
class LoginResult {
  final bool success;
  final LoginErrorType? errorType;
  final String message;

  LoginResult({required this.success, this.errorType, required this.message});
}

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _lockoutUntilKey = 'lockout_until';

  // Rate limiting constants
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const Duration _attemptWindow = Duration(minutes: 5);

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeAuth();
  }

  // Initialize Firebase Auth with proper persistence
  void _initializeAuth() {
    // Set persistence for web
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL);
    }
  }

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Get user ID
  Future<String?> getUserId() async {
    return _auth.currentUser?.uid;
  }

  // Get user email
  Future<String?> getUserEmail() async {
    return _auth.currentUser?.email;
  }

  // Get user name
  Future<String?> getUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Try to get from Firebase Auth display name
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName;
      }

      // If not available, try to get from Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['name'] != null) {
          return doc.data()!['name'] as String;
        }
      } catch (e) {
        appLog('Error getting user name from Firestore: $e');
      }
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Enhanced password validation
  static PasswordValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password cannot be empty',
        strength: PasswordStrength.none,
      );
    }

    if (password.length < 8) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must be at least 8 characters long',
        strength: PasswordStrength.weak,
      );
    }

    // Check for different character types
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialChars) strength++;
    if (password.length >= 12) strength++;

    PasswordStrength passwordStrength;
    String message;

    if (strength < 3) {
      passwordStrength = PasswordStrength.weak;
      message =
          'Password is too weak. Include uppercase, lowercase, numbers, and special characters.';
    } else if (strength < 4) {
      passwordStrength = PasswordStrength.fair;
      message = 'Password strength is fair. Consider adding more complexity.';
    } else if (strength < 5) {
      passwordStrength = PasswordStrength.good;
      message = 'Password strength is good.';
    } else {
      passwordStrength = PasswordStrength.strong;
      message = 'Password strength is strong.';
    }

    return PasswordValidationResult(
      isValid: strength >= 3,
      message: message,
      strength: passwordStrength,
    );
  }

  // Enhanced email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  // Input sanitization
  static String sanitizeInput(String input) {
    // Basic sanitization - trim whitespace
    return input.trim();
  }

  // Check if account is locked
  Future<bool> isAccountLocked(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getString('${_lockoutUntilKey}_$email');

    if (lockoutUntil != null) {
      final lockoutTime = DateTime.parse(lockoutUntil);
      if (DateTime.now().isBefore(lockoutTime)) {
        return true;
      } else {
        // Clear expired lockout
        await prefs.remove('${_lockoutUntilKey}_$email');
        await prefs.remove('${_loginAttemptsKey}_$email');
        await prefs.remove('${_lastLoginAttemptKey}_$email');
      }
    }
    return false;
  }

  // Record failed login attempt
  Future<void> _recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Get current attempts
    final attempts = prefs.getInt('${_loginAttemptsKey}_$email') ?? 0;
    final lastAttempt = prefs.getString('${_lastLoginAttemptKey}_$email');

    // Reset attempts if outside the window
    if (lastAttempt != null) {
      final lastAttemptTime = DateTime.parse(lastAttempt);
      if (now.difference(lastAttemptTime) > _attemptWindow) {
        await prefs.setInt('${_loginAttemptsKey}_$email', 1);
      } else {
        await prefs.setInt('${_loginAttemptsKey}_$email', attempts + 1);
      }
    } else {
      await prefs.setInt('${_loginAttemptsKey}_$email', 1);
    }

    await prefs.setString(
      '${_lastLoginAttemptKey}_$email',
      now.toIso8601String(),
    );

    // Lock account if max attempts reached
    if (attempts + 1 >= _maxLoginAttempts) {
      final lockoutUntil = now.add(_lockoutDuration);
      await prefs.setString(
        '${_lockoutUntilKey}_$email',
        lockoutUntil.toIso8601String(),
      );
    }
  }

  // Clear failed attempts on successful login
  Future<void> _clearFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_loginAttemptsKey}_$email');
    await prefs.remove('${_lastLoginAttemptKey}_$email');
    await prefs.remove('${_lockoutUntilKey}_$email');
  }

  // Login user with enhanced security
  Future<LoginResult> login(String email, String password) async {
    // Sanitize inputs
    final sanitizedEmail = sanitizeInput(email);
    final sanitizedPassword = password; // Don't sanitize password

    // Validate email
    if (!isValidEmail(sanitizedEmail)) {
      return LoginResult(
        success: false,
        errorType: LoginErrorType.invalidEmail,
        message: 'Invalid email format',
      );
    }

    // Check if account is locked
    if (await isAccountLocked(sanitizedEmail)) {
      return LoginResult(
        success: false,
        errorType: LoginErrorType.accountLocked,
        message:
            'Account is temporarily locked due to too many failed attempts. Please try again later.',
      );
    }

    try {
      // Sign in with email and password using Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
        password: sanitizedPassword,
      );

      final user = userCredential.user;
      if (user != null) {
        // Clear failed attempts on successful login
        await _clearFailedAttempts(sanitizedEmail);

        // Store user info in SharedPreferences (as a backup)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userIdKey, user.uid);
        await prefs.setString(_userEmailKey, user.email ?? '');

        // Get user name from Firestore if available
        String userName = 'Unknown User';
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data()?['name'] != null) {
            userName = doc.data()!['name'] as String;
            await prefs.setString(_userNameKey, userName);
          }
        } catch (e) {
          appLog('Error getting user name from Firestore: $e');
        }

        // Log login activity
        try {
          await ActivityService().logUserLogin(userName);
        } catch (e) {
          appLog('Error logging login activity: $e');
        }

        return LoginResult(success: true, message: 'Login successful');
      }

      return LoginResult(
        success: false,
        errorType: LoginErrorType.unknown,
        message: 'Login failed',
      );
    } on FirebaseAuthException catch (e) {
      // Record failed attempt
      await _recordFailedAttempt(sanitizedEmail);

      appLog('Login error (Firebase Auth): ${e.code} - ${e.message}');

      LoginErrorType errorType;
      String message;

      switch (e.code) {
        case 'user-not-found':
          errorType = LoginErrorType.userNotFound;
          message = 'No account found with this email address';
          break;
        case 'wrong-password':
          errorType = LoginErrorType.wrongPassword;
          message = 'Incorrect password';
          break;
        case 'user-disabled':
          errorType = LoginErrorType.userDisabled;
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorType = LoginErrorType.tooManyRequests;
          message = 'Too many requests. Please try again later';
          break;
        case 'invalid-email':
          errorType = LoginErrorType.invalidEmail;
          message = 'Invalid email format';
          break;
        default:
          errorType = LoginErrorType.unknown;
          message = 'Login failed. Please try again';
      }

      return LoginResult(
        success: false,
        errorType: errorType,
        message: message,
      );
    } catch (e) {
      appLog('Login error (General): $e');
      return LoginResult(
        success: false,
        errorType: LoginErrorType.unknown,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Register user with enhanced validation
  Future<bool> register(
    String name,
    String email,
    String password,
    String accountType,
  ) async {
    try {
      // Validate inputs
      final sanitizedName = sanitizeInput(name);
      final sanitizedEmail = sanitizeInput(email);

      if (sanitizedName.isEmpty) {
        appLog('Registration error: Name is empty');
        return false;
      }

      if (!isValidEmail(sanitizedEmail)) {
        appLog('Registration error: Invalid email format');
        return false;
      }

      final passwordValidation = validatePassword(password);
      if (!passwordValidation.isValid) {
        appLog('Registration error: ${passwordValidation.message}');
        return false;
      }

      // Create user with email and password using Firebase Auth
      // This automatically logs the user in
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update user profile with display name
        await user.updateDisplayName(name);

        // Reload user to ensure the display name is available
        await user.reload();

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': sanitizedName,
          'email': sanitizedEmail,
          'accountType': accountType,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'acceptedTerms': true,
          'acceptedPrivacy': true,
          'admin': false,
        });

        // Store user info in SharedPreferences (as a backup)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userIdKey, user.uid);
        await prefs.setString(_userEmailKey, sanitizedEmail);
        await prefs.setString(_userNameKey, sanitizedName);

        // Log user registration activity
        try {
          await ActivityService().logUserRegistration(
            sanitizedName,
            sanitizedEmail,
          );
        } catch (e) {
          appLog('Error logging user registration activity: $e');
        }

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      appLog('Registration error (Firebase Auth): ${e.code} - ${e.message}');

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          appLog('Registration error: Email already exists');
          break;
        case 'invalid-email':
          appLog('Registration error: Invalid email format');
          break;
        case 'weak-password':
          appLog('Registration error: Password is too weak');
          break;
        case 'operation-not-allowed':
          appLog('Registration error: Email/password accounts not enabled');
          break;
        default:
          appLog('Registration error: ${e.message}');
      }

      return false;
    } on FirebaseException catch (e) {
      appLog('Registration error (Firestore): ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      appLog('Registration error (General): $e');
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      // Validate email format first
      if (!isValidEmail(email)) {
        appLog('Password reset error: Invalid email format');
        return false;
      }

      // Send password reset email using Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
      appLog('Password reset email sent successfully to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      appLog('Password reset error (Firebase Auth): ${e.code} - ${e.message}');

      // Handle specific Firebase Auth errors for better user experience
      switch (e.code) {
        case 'user-not-found':
          appLog('Password reset error: No user found with this email');
          break;
        case 'invalid-email':
          appLog('Password reset error: Invalid email format');
          break;
        case 'too-many-requests':
          appLog(
            'Password reset error: Too many requests, please try again later',
          );
          break;
        default:
          appLog('Password reset error: ${e.message}');
      }
      return false;
    } catch (e) {
      appLog('Password reset error (General): $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Get user name before logging out
      String userName = 'Unknown User';
      try {
        final prefs = await SharedPreferences.getInstance();
        userName = prefs.getString(_userNameKey) ?? 'Unknown User';
      } catch (e) {
        appLog('Error getting user name for logout: $e');
      }

      // Log logout activity before signing out
      try {
        await ActivityService().logUserLogout(userName);
      } catch (e) {
        appLog('Error logging logout activity: $e');
      }

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
    } on FirebaseAuthException catch (e) {
      appLog('Logout error (Firebase Auth): ${e.code} - ${e.message}');
    } catch (e) {
      appLog('Logout error (General): $e');
    }
  }

  // Get current user's account type
  Future<String?> getCurrentUserAccountType() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['accountType'] != null) {
          return doc.data()!['accountType'] as String;
        }
      } catch (e) {
        appLog('Error getting user account type: $e');
      }
    }
    return null;
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      // Check both new accountType field and legacy admin field
      return data?['accountType'] == 'admin' || data?['admin'] == true;
    } catch (e) {
      appLog('Error checking admin status: $e');
      return false;
    }
  }

  // Check if current user is moderator
  Future<bool> isModerator() async {
    final accountType = await getCurrentUserAccountType();
    return accountType == 'moderator';
  }

  // Check if current user is admin or moderator
  Future<bool> isAdminOrModerator() async {
    final accountType = await getCurrentUserAccountType();
    return accountType == 'admin' || accountType == 'moderator';
  }

  // Check if current user can delete content (admin, moderator, or own content)
  Future<bool> canDeleteContent(String contentAuthorId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // If it's their own content, they can delete it
    if (currentUser.uid == contentAuthorId) return true;

    // Admin and moderator can delete any content
    return await isAdminOrModerator();
  }

  // Check if current user can access admin panel (admin only)
  Future<bool> canAccessAdminPanel() async {
    return await isAdmin();
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
