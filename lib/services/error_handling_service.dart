import 'package:flutter/material.dart';
import 'package:wonwonw2/theme/app_theme.dart';
import 'package:wonwonw2/utils/error_logger.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class ErrorHandlingService {
  static String getErrorMessage(Object error, BuildContext context) {
    if (error is NetworkError) {
      return 'network_error'.tr(context);
    } else if (error is AuthError) {
      switch (error.type) {
        case AuthErrorType.invalidCredentials:
          return 'invalid_credentials'.tr(context);
        case AuthErrorType.accountLocked:
          return 'account_locked'.tr(context);
        case AuthErrorType.sessionExpired:
          return 'session_expired'.tr(context);
        default:
          return 'auth_error'.tr(context);
      }
    } else if (error is ValidationError) {
      return error.message;
    } else {
      return 'unexpected_error'.tr(context);
    }
  }

  static Future<void> handleError(
    Object error,
    StackTrace? stackTrace,
    BuildContext context, {
    String? errorContext,
    Map<String, dynamic>? additionalData,
    VoidCallback? onRetry,
  }) async {
    // Log the error
    ErrorLogger.logError(
      error: error,
      stackTrace: stackTrace,
      context: errorContext,
      additionalData: additionalData,
    );

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error, context)),
        backgroundColor: AppTheme.errorColor,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
                : null,
      ),
    );

    // Handle specific error types
    if (error is NetworkError) {
      await _handleNetworkError(error, context);
    } else if (error is AuthError) {
      await _handleAuthError(error, context);
    } else if (error is ValidationError) {
      await _handleValidationError(error, context);
    }
  }

  static Future<void> _handleNetworkError(
    NetworkError error,
    BuildContext context,
  ) async {
    // Check network connectivity
    final isConnected = await _checkConnectivity();
    if (!isConnected) {
      // Show network settings dialog
      _showNetworkSettingsDialog(context);
    }
  }

  static Future<void> _handleAuthError(
    AuthError error,
    BuildContext context,
  ) async {
    switch (error.type) {
      case AuthErrorType.sessionExpired:
        // Clear local auth data
        await _clearAuthData();
        // Navigate to login
        _navigateToLogin(context);
        break;
      case AuthErrorType.accountLocked:
        // Show account locked dialog
        _showAccountLockedDialog(context);
        break;
      default:
        // Handle other auth errors
        break;
    }
  }

  static Future<void> _handleValidationError(
    ValidationError error,
    BuildContext context,
  ) async {
    // Show validation error dialog
    _showValidationErrorDialog(context, error.message);
  }

  static Future<bool> _checkConnectivity() async {
    // TODO: Implement connectivity check
    return true;
  }

  static void _showNetworkSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('network_error'.tr(context)),
            content: Text('check_network_settings'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Open network settings
                  Navigator.pop(context);
                },
                child: Text('settings'.tr(context)),
              ),
            ],
          ),
    );
  }

  static Future<void> _clearAuthData() async {
    // TODO: Implement auth data clearing
  }

  static void _navigateToLogin(BuildContext context) {
    // TODO: Implement navigation to login
  }

  static void _showAccountLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('account_locked'.tr(context)),
            content: Text('account_locked_message'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ok'.tr(context)),
              ),
            ],
          ),
    );
  }

  static void _showValidationErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('validation_error'.tr(context)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ok'.tr(context)),
              ),
            ],
          ),
    );
  }
}

// Custom error classes
class NetworkError implements Exception {
  final String message;
  NetworkError(this.message);
}

class AuthError implements Exception {
  final AuthErrorType type;
  final String? message;
  AuthError(this.type, [this.message]);
}

enum AuthErrorType {
  invalidCredentials,
  accountLocked,
  sessionExpired,
  unknown,
}

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
}
