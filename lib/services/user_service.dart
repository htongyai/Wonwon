import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:wonwonw2/models/user.dart';
import 'package:flutter/material.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Get current user data
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
      print('Error getting current user: $e');
    }
    return null;
  }

  // Update user profile image
  static Future<String?> uploadProfileImage() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      // Pick image from gallery or camera with initial compression
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Higher initial resolution for better cropping
        maxHeight: 1024,
        imageQuality: 90, // Higher initial quality
      );

      if (image == null) return null;

      // First compression stage - reduce size before cropping
      final Uint8List? preCompressedImage =
          await FlutterImageCompress.compressWithFile(
            image.path,
            minWidth: 800,
            minHeight: 800,
            quality: 85,
            rotate: 0,
          );

      if (preCompressedImage == null) return null;

      // Save compressed image to temporary file for cropping
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/temp_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(preCompressedImage);

      // Crop image to 1:1 aspect ratio
      final CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: tempFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Image',
            toolbarColor: const Color(0xFFC3C130),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Image',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (croppedImage == null) return null;

      // Second compression stage - final compression for upload
      final Uint8List? finalCompressedImage =
          await FlutterImageCompress.compressWithFile(
            croppedImage.path,
            minWidth: 256, // Final size for profile image
            minHeight: 256,
            quality: 75, // Optimized quality for web
            rotate: 0,
            format: CompressFormat.jpeg,
          );

      if (finalCompressedImage == null) return null;

      // Third compression stage - ultra compression for mobile/web optimization
      final Uint8List? ultraCompressedImage =
          await FlutterImageCompress.compressWithList(
            finalCompressedImage,
            minWidth: 256,
            minHeight: 256,
            quality: 70, // Slightly lower quality for better compression
            rotate: 0,
            format: CompressFormat.jpeg,
          );

      if (ultraCompressedImage == null) return null;

      // Upload to Firebase Storage
      final String fileName =
          'profile_images/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putData(ultraCompressedImage);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user document with new profile image URL
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      // Get current user data
      final user = await getCurrentUser();
      if (user?.profileImageUrl == null) return true;

      // Delete from Firebase Storage
      final Reference storageRef = _storage.refFromURL(user!.profileImageUrl!);
      await storageRef.delete();

      // Update user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': null,
      });

      return true;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }

  // Update user profile data
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
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get all users (for admin functionality)
  static Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      print('Found ${snapshot.docs.length} users in Firebase');

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
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Update user account type
  static Future<bool> updateUserAccountType(
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
      print('Error updating user account type: $e');
      return false;
    }
  }

  // Update user status
  static Future<bool> updateUserStatus(String userId, String newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      // Check both new accountType field and legacy admin field
      return data?['accountType'] == 'admin' || data?['admin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Delete user
  static Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
