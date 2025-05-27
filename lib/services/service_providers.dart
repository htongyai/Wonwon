import 'package:flutter/material.dart';
import 'package:wonwonw2/services/location_service.dart';
import 'package:wonwonw2/services/auth_state_service.dart';

/// A global location service instance
final locationService = LocationService();

/// A global auth state service instance
final authStateService = AuthStateService();

/// Provides access to various services in the app
class ServiceProvider extends InheritedWidget {
  final LocationService locationService;
  final AuthStateService authStateService;

  const ServiceProvider({
    super.key,
    required super.child,
    required this.locationService,
    required this.authStateService,
  });

  static ServiceProvider of(BuildContext context) {
    final ServiceProvider? result =
        context.dependOnInheritedWidgetOfExactType<ServiceProvider>();
    assert(result != null, 'No ServiceProvider found in context');
    return result!;
  }

  static LocationService locationOf(BuildContext context) {
    return of(context).locationService;
  }

  static AuthStateService authStateOf(BuildContext context) {
    return of(context).authStateService;
  }

  @override
  bool updateShouldNotify(covariant ServiceProvider oldWidget) {
    return oldWidget.locationService != locationService ||
        oldWidget.authStateService != authStateService;
  }
}
