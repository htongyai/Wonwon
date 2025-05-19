import 'package:flutter/material.dart';
import 'package:wonwonw2/services/location_service.dart';

/// A global location service instance
final locationService = LocationService();

/// Provides access to various services in the app
class ServiceProvider extends InheritedWidget {
  final LocationService locationService;

  const ServiceProvider({
    super.key,
    required super.child,
    required this.locationService,
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

  @override
  bool updateShouldNotify(covariant ServiceProvider oldWidget) {
    return oldWidget.locationService != locationService;
  }
}
