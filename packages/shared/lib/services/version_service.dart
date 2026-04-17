import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/services/version_service_platform.dart' as platform;

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
      await getCurrentVersion();
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
      final storedVersion = platform.getStoredVersion();

      appLog(
        'Version check - Current: $currentVersion, Stored: $storedVersion',
      );

      if (storedVersion == null || storedVersion != currentVersion) {
        appLog('New version detected, clearing cache...');
        await platform.clearAppCache();
        platform.storeVersion(currentVersion);

        await _updateUserAppVersion(currentVersion);

        return true;
      }

      await _updateUserAppVersion(currentVersion);

      return false;
    } catch (e) {
      appLog('Error in version check: $e');
      return false;
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
    platform.forceReloadPage();
  }

  /// Clear all caches and force a page reload (for force update).
  /// Always attempts the reload even if cache clearing fails.
  Future<void> clearCacheAndReload() async {
    try {
      await platform.clearAppCache();
    } catch (e) {
      appLog('Error clearing cache: $e');
    }
    platform.forceReloadPage();
  }

  // ── Force Update Check ──────────────────────────────────────────────

  /// Check if a force update is required.
  ///
  /// Reads `config/app` from Firestore which should contain:
  /// - `requiredVersion`: minimum version all users must run (e.g. "2.2.3")
  ///
  /// If the current app version is lower than `requiredVersion`, users must
  /// reload to get the latest deployed build.
  Future<ForceUpdateResult> checkForceUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final configDoc =
          await _firestore.collection('config').doc('app').get();

      if (!configDoc.exists) {
        return ForceUpdateResult(
            isRequired: false, currentVersion: currentVersion);
      }

      final data = configDoc.data() as Map<String, dynamic>? ?? {};
      final requiredVersion = data['requiredVersion'] as String?;

      if (requiredVersion == null || requiredVersion.isEmpty) {
        return ForceUpdateResult(
            isRequired: false, currentVersion: currentVersion);
      }

      final isOutdated = _isVersionLessThan(currentVersion, requiredVersion);

      appLog(
        'Force update check — current: $currentVersion, '
        'required: $requiredVersion, outdated: $isOutdated',
      );

      return ForceUpdateResult(
        isRequired: isOutdated,
        currentVersion: currentVersion,
        requiredVersion: requiredVersion,
      );
    } catch (e) {
      appLog('Force update check error: $e');
      return ForceUpdateResult(
          isRequired: false, currentVersion: _currentVersion ?? '0.0.0');
    }
  }

  /// Update the required version in Firestore (admin only).
  Future<void> setRequiredVersion(String version) async {
    await _firestore.collection('config').doc('app').set({
      'requiredVersion': version,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    appLog('Set required version to: $version');
  }

  /// Compare two semantic version strings. Returns `true` if [a] < [b].
  bool _isVersionLessThan(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    while (aParts.length < 3) aParts.add(0);
    while (bParts.length < 3) bParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (aParts[i] < bParts[i]) return true;
      if (aParts[i] > bParts[i]) return false;
    }
    return false; // equal
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

  /// Get the required version from Firestore (for display)
  Future<String?> getRequiredVersion() async {
    try {
      final configDoc =
          await _firestore.collection('config').doc('app').get();
      if (!configDoc.exists) return null;
      final data = configDoc.data() as Map<String, dynamic>? ?? {};
      return data['requiredVersion'] as String?;
    } catch (e) {
      appLog('Error getting required version: $e');
      return null;
    }
  }

  /// Get version comparison status
  Future<String> getVersionStatus(String userVersion) async {
    final currentVersion = await getCurrentVersion();

    if (userVersion == currentVersion) {
      return 'latest';
    }

    final userParts = userVersion.split('.').map(int.tryParse).toList();
    final currentParts = currentVersion.split('.').map(int.tryParse).toList();

    while (userParts.length < 3) userParts.add(0);
    while (currentParts.length < 3) currentParts.add(0);

    for (int i = 0; i < 3; i++) {
      final userPart = userParts[i] ?? 0;
      final currentPart = currentParts[i] ?? 0;

      if (userPart < currentPart) {
        return 'outdated';
      } else if (userPart > currentPart) {
        return 'newer';
      }
    }

    return 'latest';
  }
}

/// Result of a force update check.
class ForceUpdateResult {
  final bool isRequired;
  final String? currentVersion;
  final String? requiredVersion;

  const ForceUpdateResult({
    required this.isRequired,
    this.currentVersion,
    this.requiredVersion,
  });
}
