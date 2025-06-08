import 'package:flutter/material.dart';
import 'package:wonwonw2/theme/app_theme.dart';
import 'package:wonwonw2/utils/error_logger.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace?)? fallbackBuilder;

  const ErrorBoundary({Key? key, required this.child, this.fallbackBuilder})
    : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _error = details.exception;
      _stackTrace = details.stack;
      ErrorLogger.logError(
        error: details.exception,
        stackTrace: details.stack,
        context: 'ErrorBoundary',
      );
      return _buildErrorWidget(details);
    };
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context, details.exception, details.stack);
    }

    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTheme.getTitleStyle().copyWith(
                color: AppTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re sorry, but something went wrong. Please try again later.',
              style: AppTheme.getSubtitleStyle(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _stackTrace = null;
                });
              },
              style: AppTheme.getPrimaryButtonStyle(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(
        FlutterErrorDetails(exception: _error!, stack: _stackTrace),
      );
    }
    return widget.child;
  }
}
