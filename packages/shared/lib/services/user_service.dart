import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared/models/user.dart';
import 'package:shared/utils/app_logger.dart';

import 'user_service_image_helper.dart'
    if (dart.library.io) 'user_service_image_io.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static Future<User?> getCurrentUser() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      appLog('Error getting current user: $e');
    }
    return null;
  }

  static Future<String?> uploadProfileImage() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image == null) return null;

      Uint8List imageBytes;

      if (kIsWeb) {
        imageBytes = await image.readAsBytes();
      } else {
        final processed = await processImageNative(image.path);
        if (processed == null) return null;
        imageBytes = processed;
      }

      final String fileName =
          'profile_images/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putData(imageBytes);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      appLog('Error uploading profile image: $e');
      return null;
    }
  }

  static Future<bool> deleteProfileImage() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final user = await getCurrentUser();
      if (user?.profileImageUrl == null) return true;

      final Reference storageRef = _storage.refFromURL(user!.profileImageUrl!);
      await storageRef.delete();

      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': null,
      });

      return true;
    } catch (e) {
      appLog('Error deleting profile image: $e');
      return false;
    }
  }

  static Future<bool> updateUserProfile({String? name, String? email}) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;

      await _firestore.collection('users').doc(currentUser.uid).update(updates);
      return true;
    } catch (e) {
      appLog('Error updating user profile: $e');
      return false;
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').limit(500).get();
      appLog('Found ${snapshot.docs.length} users in Firebase');

      return snapshot.docs.map((doc) {
        final data = doc.data();

        if (data['admin'] == true) {
          data['accountType'] = 'admin';
        } else if (data['accountType'] == null) {
          data['accountType'] = 'user';
        }

        if (data['status'] == null) {
          data['status'] = 'active';
        }

        if (data['createdAt'] == null) {
          data['createdAt'] = DateTime.now().toIso8601String();
        }

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

  static Future<bool> updateUserAccountType(
    String userId,
    String newAccountType,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'accountType': newAccountType,
        'admin': newAccountType == 'admin',
      });
      return true;
    } catch (e) {
      appLog('Error updating user account type: $e');
      return false;
    }
  }

  static Future<bool> updateUserStatus(String userId, String newStatus) async {
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

  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      return data?['accountType'] == 'admin' || data?['admin'] == true;
    } catch (e) {
      appLog('Error checking admin status: $e');
      return false;
    }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      appLog('Error deleting user: $e');
      return false;
    }
  }
}
