import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/utils/error_logger.dart';
import 'package:shared/localization/app_localizations_wrapper.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace?)? fallbackBuilder;

  const ErrorBoundary({Key? key, required this.child, this.fallbackBuilder})
    : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  static bool _globalHandlerSet = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    if (!_globalHandlerSet) {
      _globalHandlerSet = true;
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        ErrorLogger.logError(
          error: details.exception,
          stackTrace: details.stack,
          context: 'ErrorBoundary',
        );
      };
    }
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) {
    if (widget.fallbackBuilder != null) {
      return widget.fallbackBuilder!(context, details.exception, details.stack);
    }

    return Material(
      child: SafeArea(
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
              'something_went_wrong'.tr(context),
              style: AppTheme.getTitleStyle().copyWith(
                color: AppTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
              const SizedBox(height: 8),
              Text(
              'error_try_again'.tr(context),
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
              child: Text('try_again'.tr(context)),
              ),
            ],
          ),
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
