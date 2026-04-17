import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    appLog('Error occurred: $error');

    String message = customMessage ?? _getLocalizedErrorMessage(context, error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: Text('retry'.tr(context),
                    style: const TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'cancel'.tr(context),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String _getLocalizedErrorMessage(
      BuildContext context, dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('socket') ||
        errorStr.contains('connection')) {
      return 'network_error'.tr(context);
    } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'permission_error'.tr(context);
    } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'timeout_error'.tr(context);
    } else if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'not_found_error'.tr(context);
    } else if (errorStr.contains('unauthorized') || errorStr.contains('401') ||
        errorStr.contains('unauthenticated')) {
      return 'unauthorized_error'.tr(context);
    } else if (errorStr.contains('server') || errorStr.contains('500') ||
        errorStr.contains('503')) {
      return 'server_error'.tr(context);
    } else if (errorStr.contains('validation') ||
        errorStr.contains('invalid input')) {
      return 'validation_error'.tr(context);
    } else {
      return 'unexpected_error'.tr(context);
    }
  }

  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'loading'.tr(context)),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText ?? 'cancel'.tr(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText ?? 'confirm_button'.tr(context)),
          ),
        ],
      ),
    );
  }
}
