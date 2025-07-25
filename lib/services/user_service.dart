import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wonwonw2/models/user.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      appLog('Found ${snapshot.docs.length} users in Firebase');

      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Handle legacy admin field - if admin is true, set accountType to admin
        if (data['admin'] == true) {
          data['accountType'] = 'admin';
        } else if (data['accountType'] == null) {
          data['accountType'] =
              'user'; // Default to user if no accountType specified
        }

        // Ensure status field exists
        if (data['status'] == null) {
          data['status'] = 'active'; // Default to active
        }

        // Ensure createdAt field exists
        if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }

        // Ensure acceptedTerms and acceptedPrivacy exist
        if (data['acceptedTerms'] == null) {
          data['acceptedTerms'] = false;
        }
        if (data['acceptedPrivacy'] == null) {
          data['acceptedPrivacy'] = false;
        }

        return User.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      appLog('Error fetching all users: $e');
      return [];
    }
  }

  // Update user account type
  Future<bool> updateUserAccountType(
    String userId,
    String newAccountType,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'accountType': newAccountType,
        'admin': newAccountType == 'admin', // Keep legacy admin field in sync
      });
      return true;
    } catch (e) {
      appLog('Error updating user account type: $e');
      return false;
    }
  }

  // Update user status
  Future<bool> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      appLog('Error updating user status: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;

    // This is a simplified version - in practice you'd want to fetch from Firestore
    return User(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      accountType: 'user', // Default, should be fetched from Firestore
      status: 'active',
      createdAt: DateTime.now(),
      acceptedTerms: true,
      acceptedPrivacy: true,
    );
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      // Check both new accountType field and legacy admin field
      return data?['accountType'] == 'admin' || data?['admin'] == true;
    } catch (e) {
      appLog('Error checking admin status: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      appLog('Error deleting user: $e');
      return false;
    }
  }
}
