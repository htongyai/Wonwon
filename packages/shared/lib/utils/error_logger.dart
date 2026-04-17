import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ErrorLogger {
  static void logError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        'Error in $context: $error',
        error: error,
        stackTrace: stackTrace,
      );
      if (additionalData != null) {
        developer.log('Additional data: $additionalData');
      }
    }

    _reportError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      additionalData: additionalData,
    );
  }

  static Future<void> _reportError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Error reporting via appLog; integrate Firebase Crashlytics or
      // Sentry here when a production reporting service is needed.
    } catch (e) {
      // Fallback logging if error reporting fails
      developer.log('Failed to report error: $e', error: e);
    }
  }

  static void logInfo({
    required String message,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      developer.log(message, name: 'Info');
      if (additionalData != null) {
        developer.log('Additional data: $additionalData');
      }
    }
  }

  static void logWarning({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'Warning',
        error: error,
        stackTrace: stackTrace,
      );
      if (additionalData != null) {
        developer.log('Additional data: $additionalData');
      }
    }
  }
}
