import 'dart:async';

class NotificationController {
  static final NotificationController _instance =
      NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  final StreamController<bool> _sidebarController =
      StreamController<bool>.broadcast();

  Stream<bool> get sidebarStream => _sidebarController.stream;

  void openSidebar() {
    _sidebarController.add(true);
  }

  void closeSidebar() {
    _sidebarController.add(false);
  }

  void dispose() {
    _sidebarController.close();
  }
}
