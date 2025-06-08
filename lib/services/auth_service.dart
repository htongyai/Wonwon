import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // Use Firebase Auth state instead of SharedPreferences
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

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      // Sign in with email and password using Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Store user info in SharedPreferences (as a backup)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userIdKey, user.uid);
        await prefs.setString(_userEmailKey, user.email ?? '');

        // Get user name from Firestore if available
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data()?['name'] != null) {
            await prefs.setString(_userNameKey, doc.data()!['name'] as String);
          }
        } catch (e) {
          appLog('Error getting user name from Firestore: $e');
        }

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      appLog('Login error (Firebase Auth): ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      appLog('Login error (General): $e');
      return false;
    }
  }

  // Register user
  Future<bool> register(String name, String email, String password) async {
    try {
      // Create user with email and password using Firebase Auth
      // This automatically logs the user in
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
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
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'acceptedTerms': true,
          'acceptedPrivacy': true,
          'admin': false,
        });

        // Store user info in SharedPreferences (as a backup)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userIdKey, user.uid);
        await prefs.setString(_userEmailKey, email);
        await prefs.setString(_userNameKey, name);

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      appLog('Registration error (Firebase Auth): ${e.code} - ${e.message}');
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
      // Send password reset email using Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      appLog('Password reset error (Firebase Auth): ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      appLog('Password reset error (General): $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
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
}
