import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wonwonw2/widgets/notification_sidebar.dart';
import 'package:wonwonw2/services/notification_controller.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  bool _isNotificationSidebarOpen = false;
  late StreamSubscription<bool> _sidebarSubscription;

  @override
  void initState() {
    super.initState();
    _sidebarSubscription = NotificationController().sidebarStream.listen((
      isOpen,
    ) {
      setState(() {
        _isNotificationSidebarOpen = isOpen;
      });
    });
  }

  @override
  void dispose() {
    _sidebarSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Notification sidebar
        NotificationSidebar(
          isOpen: _isNotificationSidebarOpen,
          onClose: () {
            NotificationController().closeSidebar();
          },
        ),
      ],
    );
  }
}
