import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/services/notification_service.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

class NotificationIcon extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const NotificationIcon({Key? key, required this.onTap, this.size = 24})
    : super(key: key);

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  late final Stream<int> _unreadStream = NotificationService.getUnreadCount();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unreadStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasError ? 0 : (snapshot.data ?? 0);

        return Semantics(
          label: 'notifications'.tr(context),
          button: true,
          child: Material(
          color: Colors.transparent,
          child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                FaIcon(
                  FontAwesomeIcons.bell,
                  size: widget.size,
                  color: AppConstants.primaryColor,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
        );
      },
    );
  }
}
