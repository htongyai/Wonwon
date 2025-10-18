import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'dart:html' as html;

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentVersion;
  String? _buildNumber;

  /// Get the current app version
  Future<String> getCurrentVersion() async {
    if (_currentVersion == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _currentVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      } catch (e) {
        appLog('Error getting package info: $e');
        _currentVersion = '1.0.0';
        _buildNumber = '1';
      }
    }
    return _currentVersion!;
  }

  /// Get the current build number
  Future<String> getBuildNumber() async {
    if (_buildNumber == null) {
      await getCurrentVersion(); // This will set both version and build number
    }
    return _buildNumber!;
  }

  /// Get full version string (version+build)
  Future<String> getFullVersionString() async {
    final version = await getCurrentVersion();
    final build = await getBuildNumber();
    return '$version+$build';
  }

  /// Check for version updates and clear cache if needed
  Future<bool> checkAndHandleVersionUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final storedVersion = html.window.localStorage['app_version'];

      appLog(
        'Version check - Current: $currentVersion, Stored: $storedVersion',
      );

      if (storedVersion == null || storedVersion != currentVersion) {
        appLog('New version detected, clearing cache...');
        await _clearAppCache();
        html.window.localStorage['app_version'] = currentVersion;

        // Update user's app version in Firestore
        await _updateUserAppVersion(currentVersion);

        return true; // Version was updated
      }

      // Still update user version in case it wasn't recorded
      await _updateUserAppVersion(currentVersion);

      return false; // No version update
    } catch (e) {
      appLog('Error in version check: $e');
      return false;
    }
  }

  /// Clear all app caches
  Future<void> _clearAppCache() async {
    try {
      // Clear service worker caches
      final cacheNames = await html.window.caches?.keys();
      if (cacheNames != null) {
        for (final cacheName in cacheNames) {
          await html.window.caches?.delete(cacheName);
          appLog('Cleared cache: $cacheName');
        }
      }

      // Clear localStorage (except version)
      final version = html.window.localStorage['app_version'];
      html.window.localStorage.clear();
      if (version != null) {
        html.window.localStorage['app_version'] = version;
      }

      // Clear sessionStorage
      html.window.sessionStorage.clear();

      appLog('App cache cleared successfully');
    } catch (e) {
      appLog('Error clearing cache: $e');
    }
  }

  /// Update user's app version in Firestore
  Future<void> _updateUserAppVersion(String version) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final fullVersion = await getFullVersionString();
        await _firestore.collection('users').doc(user.uid).update({
          'appVersion': version,
          'fullAppVersion': fullVersion,
          'lastVersionUpdate': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        appLog('Updated user app version to: $fullVersion');
      }
    } catch (e) {
      appLog('Error updating user app version: $e');
    }
  }

  /// Force a hard reload of the application
  void forceReload() {
    html.window.location.reload();
  }

  /// Get version info for display
  Future<Map<String, String>> getVersionInfo() async {
    final version = await getCurrentVersion();
    final build = await getBuildNumber();
    final fullVersion = await getFullVersionString();

    return {'version': version, 'build': build, 'fullVersion': fullVersion};
  }

  /// Check if user is on the latest version (for admin dashboard)
  Future<bool> isUserOnLatestVersion(String userVersion) async {
    final currentVersion = await getCurrentVersion();
    return userVersion == currentVersion;
  }

  /// Get version comparison status
  Future<String> getVersionStatus(String userVersion) async {
    final currentVersion = await getCurrentVersion();

    if (userVersion == currentVersion) {
      return 'latest';
    }

    // Simple version comparison (assumes semantic versioning)
    final userParts = userVersion.split('.').map(int.tryParse).toList();
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();

    // Pad shorter version with zeros
    while (userParts.length < 3) userParts.add(0);
    while (currentParts.length < 3) currentParts.add(0);

    for (int i = 0; i < 3; i++) {
      final userPart = userParts[i] ?? 0;
      final currentPart = currentParts[i] ?? 0;

      if (userPart < currentPart) {
        return 'outdated';
      } else if (userPart > currentPart) {
        return 'newer'; // User somehow has a newer version
      }
    }

    return 'latest';
  }
}
