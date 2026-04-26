import 'package:flutter/material.dart';
import 'package:shared/services/version_service.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/localization/app_localizations_wrapper.dart';
import 'package:shared/utils/app_logger.dart';

/// Wraps the app's home widget and blocks access when the current version
/// is older than the required version stored in Firestore (`config/app`).
///
/// On web, tapping "Update Now" clears all caches and reloads the page so the
/// latest deployed build is fetched from the server.
class ForceUpdateChecker extends StatefulWidget {
  final Widget child;

  const ForceUpdateChecker({Key? key, required this.child}) : super(key: key);

  @override
  State<ForceUpdateChecker> createState() => _ForceUpdateCheckerState();
}

class _ForceUpdateCheckerState extends State<ForceUpdateChecker> {
  bool _isChecking = true;
  bool _needsUpdate = false;
  String? _requiredVersion;
  String? _currentVersion;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final result = await VersionService().checkForceUpdate();
      if (mounted) {
        setState(() {
          _isChecking = false;
          if (result.isRequired) {
            _needsUpdate = true;
            _requiredVersion = result.requiredVersion;
            _currentVersion = result.currentVersion;
          }
        });
      }
    } catch (e) {
      // If the check fails, let the user through — don't block on errors.
      appLog('ForceUpdateChecker error: $e');
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _isUpdating = true);
    try {
      await VersionService().clearCacheAndReload();
    } catch (e) {
      // If reload fails, re-enable the button so user can retry
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show a brief loading indicator while checking version
    if (_isChecking) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    if (_needsUpdate) {
      return _buildUpdateScreen();
    }
    return widget.child;
  }

  Widget _buildUpdateScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: 48,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 28),

              // Title (localized)
              Text(
                'force_update_title'.tr(context),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'force_update_subtitle'.tr(context),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Version info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'force_update_current'.tr(context),
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'v$_currentVersion',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'force_update_latest'.tr(context),
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'v$_requiredVersion',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'force_update_message'.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Update button
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppConstants.primaryColor.withAlpha(150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'force_update_button'.tr(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
