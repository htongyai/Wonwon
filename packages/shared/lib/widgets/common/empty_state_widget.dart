import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/localization/app_localizations_wrapper.dart';

/// Widget for displaying empty states
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final FaIcon? faIcon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final EdgeInsetsGeometry? padding;
  final bool showButton;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.faIcon,
    this.buttonText,
    this.onButtonPressed,
    this.padding,
    this.showButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: faIcon ?? 
                Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 40,
                  color: AppConstants.primaryColor,
                ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (showButton && buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText!,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state for no shops found
class NoShopsFoundWidget extends StatelessWidget {
  final VoidCallback? onRefresh;
  final String? searchQuery;

  const NoShopsFoundWidget({
    Key? key,
    this.onRefresh,
    this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: searchQuery != null ? 'no_shops_found'.tr(context) : 'no_shops_available'.tr(context),
      subtitle: searchQuery != null 
          ? 'try_adjusting_search'.tr(context)
          : 'no_shops_in_area'.tr(context),
      faIcon: const FaIcon(
        FontAwesomeIcons.screwdriverWrench,
        size: 40,
        color: AppConstants.primaryColor,
      ),
      buttonText: 'refresh'.tr(context),
      onButtonPressed: onRefresh,
    );
  }
}

/// Empty state for no reviews
class NoReviewsFoundWidget extends StatelessWidget {
  final VoidCallback? onAddReview;

  const NoReviewsFoundWidget({
    Key? key,
    this.onAddReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'no_reviews_empty'.tr(context),
      subtitle: 'be_first_review_msg'.tr(context),
      icon: Icons.rate_review_outlined,
      buttonText: 'write_review'.tr(context),
      onButtonPressed: onAddReview,
    );
  }
}

/// Empty state for no saved locations
class NoSavedLocationsWidget extends StatelessWidget {
  final VoidCallback? onExplore;

  const NoSavedLocationsWidget({
    Key? key,
    this.onExplore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'no_saved_empty'.tr(context),
      subtitle: 'start_exploring_msg'.tr(context),
      icon: Icons.bookmark_border,
      buttonText: 'explore_shops'.tr(context),
      onButtonPressed: onExplore,
    );
  }
}

/// Empty state for no forum topics
class NoForumTopicsWidget extends StatelessWidget {
  final VoidCallback? onCreateTopic;

  const NoForumTopicsWidget({
    Key? key,
    this.onCreateTopic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'no_discussions_empty'.tr(context),
      subtitle: 'start_conversation_msg'.tr(context),
      icon: Icons.forum_outlined,
      buttonText: 'create_topic'.tr(context),
      onButtonPressed: onCreateTopic,
    );
  }
}

/// Empty state for no search results
class NoSearchResultsWidget extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const NoSearchResultsWidget({
    Key? key,
    required this.searchQuery,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'no_results_for'.tr(context).replaceAll('{query}', searchQuery),
      subtitle: 'try_different_keywords'.tr(context),
      icon: Icons.search_off,
      buttonText: 'clear_search'.tr(context),
      onButtonPressed: onClearSearch,
    );
  }
}

/// Empty state for network error
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'connection_error'.tr(context),
      subtitle: 'check_connection'.tr(context),
      icon: Icons.wifi_off,
      buttonText: 'retry'.tr(context),
      onButtonPressed: onRetry,
    );
  }
}

/// Empty state for permission denied
class PermissionDeniedWidget extends StatelessWidget {
  final String permission;
  final VoidCallback? onRequestPermission;

  const PermissionDeniedWidget({
    Key? key,
    required this.permission,
    this.onRequestPermission,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'permission_required_title'.tr(context),
      subtitle: 'grant_permission_msg'.tr(context).replaceAll('{permission}', permission),
      icon: Icons.lock_outline,
      buttonText: 'Grant Permission',
      onButtonPressed: onRequestPermission,
    );
  }
}
