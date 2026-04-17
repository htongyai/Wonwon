import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:shared/models/notification.dart';
import 'package:wonwon_client/screens/forum_topic_detail_screen.dart';
import 'package:wonwon_client/screens/shop_detail_screen.dart';
import 'package:shared/services/notification_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/services/analytics_service.dart';

class NotificationSidebar extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const NotificationSidebar({
    Key? key,
    required this.isOpen,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NotificationSidebar> createState() => _NotificationSidebarState();
}

class _NotificationSidebarState extends State<NotificationSidebar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // Mark all notifications as read when sidebar closes
        _markAllAsReadOnClose();
      }
    }
  }

  /// Mark all notifications as read when sidebar closes
  /// This way users see unread indicators while browsing, then they're
  /// marked read once they close the panel.
  Future<void> _markAllAsReadOnClose() async {
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      appLog('Error marking notifications as read on close: $e');
    }
  }

  // ── Localized display helpers ──────────────────────────────────────────

  /// Generate a localized title based on notification type
  String _localizedTitle(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.forumReply:
        return 'notif_forum_reply_title'.tr(context);
      case NotificationType.forumLike:
        return 'notif_forum_like_title'.tr(context);
      case NotificationType.reviewReply:
        return 'notif_review_reply_title'.tr(context);
      case NotificationType.shopApproved:
        return 'notif_shop_approved_title'.tr(context);
      case NotificationType.shopRejected:
        return 'notif_shop_rejected_title'.tr(context);
      case NotificationType.announcement:
        return 'notif_announcement_title'.tr(context);
      case NotificationType.systemMessage:
        return 'notif_system_title'.tr(context);
    }
  }

  /// Generate a localized message with data substitution
  String _localizedMessage(NotificationModel notification) {
    final data = notification.data;
    switch (notification.type) {
      case NotificationType.forumReply:
        return 'notif_forum_reply_msg'
            .tr(context)
            .replaceAll('{name}', data['authorName']?.toString() ?? '')
            .replaceAll('{topic}', data['topicTitle']?.toString() ?? '');
      case NotificationType.forumLike:
        return 'notif_forum_like_msg'
            .tr(context)
            .replaceAll('{name}', data['likerName']?.toString() ?? '')
            .replaceAll('{topic}', data['topicTitle']?.toString() ?? '');
      case NotificationType.reviewReply:
        return 'notif_review_reply_msg'
            .tr(context)
            .replaceAll('{name}', data['authorName']?.toString() ?? '')
            .replaceAll('{shop}', data['shopName']?.toString() ?? '');
      case NotificationType.shopApproved:
        return 'notif_shop_approved_msg'
            .tr(context)
            .replaceAll('{shop}', data['shopName']?.toString() ?? '');
      case NotificationType.shopRejected:
        return 'notif_shop_rejected_msg'
            .tr(context)
            .replaceAll('{shop}', data['shopName']?.toString() ?? '');
      case NotificationType.announcement:
      case NotificationType.systemMessage:
        // These use freeform text stored at creation time
        return notification.message;
    }
  }

  /// Generate a localized time-ago string
  String _localizedTimeAgo(NotificationModel notification) {
    final difference = DateTime.now().difference(notification.createdAt);

    String template;
    int count;

    if (difference.inMinutes < 1) {
      // Just now — use the minutes template with 0 or 1
      template = 'time_minutes_ago'.tr(context);
      count = 1;
    } else if (difference.inMinutes < 60) {
      template = 'time_minutes_ago'.tr(context);
      count = difference.inMinutes;
    } else if (difference.inHours < 24) {
      template = 'time_hours_ago'.tr(context);
      count = difference.inHours;
    } else if (difference.inDays < 7) {
      template = 'time_short_days_ago'.tr(context);
      count = difference.inDays;
    } else {
      template = 'time_short_weeks_ago'.tr(context);
      count = (difference.inDays / 7).floor();
    }

    return template.replaceAll('{count}', count.toString());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = ResponsiveBreakpoints.isSmallPhone(screenWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);

    // Calculate responsive sidebar width:
    // Small phones (<400px): full screen width
    // Other mobile: 85% of screen width
    // Tablet: fixed 350px
    // Desktop: fixed 400px
    double sidebarWidth;
    if (isSmallPhone) {
      sidebarWidth = screenWidth; // Full width on small phones
    } else if (isMobile) {
      sidebarWidth = screenWidth * 0.85; // 85% of screen width on small screens
    } else if (isTablet) {
      sidebarWidth = 350; // Fixed width for medium screens
    } else {
      sidebarWidth = 400; // Fixed width for desktop
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            if (widget.isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.black.withValues(alpha: _fadeAnimation.value),
                  ),
                ),
              ),
            // Sidebar
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(
                  sidebarWidth * _slideAnimation.value,
                  0,
                ),
                child: Container(
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(child: _buildNotificationsList()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.bell,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'notifications_title'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasError ? 0 : (snapshot.data ?? 0);
              if (unreadCount > 0) {
                return SizedBox(
                  height: 44,
                  child: GestureDetector(
                    onTap: _isMarkingAllRead ? null : () async {
                      setState(() => _isMarkingAllRead = true);
                      try {
                        await NotificationService.markAllAsRead();
                      } finally {
                        if (mounted) setState(() => _isMarkingAllRead = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'mark_all_read'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'no_notifications_available'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'notifications_appear_here'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'no_notifications_yet'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'notifications_appear_here'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              notification.isRead
                  ? Colors.grey.withValues(alpha: 0.1)
                  : notification.color.withValues(alpha: 0.2),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _localizedTitle(notification),
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                color:
                                    notification.isRead
                                        ? Colors.grey[600]
                                        : AppConstants.darkColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _localizedMessage(notification),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _localizedTimeAgo(notification),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  onSelected:
                      (value) => _handleNotificationAction(value, notification),
                  itemBuilder:
                      (context) => [
                        if (!notification.isRead)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 16),
                                const SizedBox(width: 8),
                                Text('mark_as_read'.tr(context)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'delete_button'.tr(context),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    try {
      // Mark as read if not already read
      if (!notification.isRead) {
        await NotificationService.markAsRead(notification.id);
      }
      AnalyticsService.safeLog(() => AnalyticsService().logNotificationTap(type: notification.type.name, relatedId: notification.relatedId));
    } catch (e) {
      appLog('Error marking notification as read: $e');
    }

    if (!mounted) return;

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.forumReply:
      case NotificationType.forumLike:
        if (notification.relatedId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      ForumTopicDetailScreen(topicId: notification.relatedId!),
            ),
          );
        }
        break;
      case NotificationType.reviewReply:
        if (notification.data['shopId'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      ShopDetailScreen(shopId: notification.data['shopId']),
            ),
          );
        }
        break;
      case NotificationType.shopApproved:
      case NotificationType.shopRejected:
        if (notification.relatedId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      ShopDetailScreen(shopId: notification.relatedId!),
            ),
          );
        }
        break;
      case NotificationType.announcement:
      case NotificationType.systemMessage:
        // Show full message in dialog
        _showNotificationDialog(notification);
        break;
    }

    widget.onClose();
  }

  void _handleNotificationAction(
    String action,
    NotificationModel notification,
  ) async {
    try {
      switch (action) {
        case 'mark_read':
          await NotificationService.markAsRead(notification.id);
          break;
        case 'delete':
          await NotificationService.deleteNotification(notification.id);
          break;
      }
    } catch (e) {
      appLog('Error handling notification action: $e');
    }
  }

  void _showNotificationDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(notification.icon, color: notification.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _localizedTitle(notification),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedMessage(notification),
                  style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  _localizedTimeAgo(notification),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('close_button'.tr(context)),
              ),
            ],
          ),
    );
  }
}
