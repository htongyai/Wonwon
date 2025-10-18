import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';

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
              color: AppConstants.primaryColor.withOpacity(0.1),
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
      title: searchQuery != null ? 'No shops found' : 'No shops available',
      subtitle: searchQuery != null 
          ? 'Try adjusting your search criteria or location'
          : 'There are no repair shops in your area yet',
      faIcon: const FaIcon(
        FontAwesomeIcons.screwdriverWrench,
        size: 40,
        color: AppConstants.primaryColor,
      ),
      buttonText: 'Refresh',
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
      title: 'No reviews yet',
      subtitle: 'Be the first to share your experience with this shop',
      icon: Icons.rate_review_outlined,
      buttonText: 'Write Review',
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
      title: 'No saved locations',
      subtitle: 'Start exploring and save your favorite repair shops',
      icon: Icons.bookmark_border,
      buttonText: 'Explore Shops',
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
      title: 'No discussions yet',
      subtitle: 'Start a conversation with the community',
      icon: Icons.forum_outlined,
      buttonText: 'Create Topic',
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
      title: 'No results for "$searchQuery"',
      subtitle: 'Try different keywords or check your spelling',
      icon: Icons.search_off,
      buttonText: 'Clear Search',
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
      title: 'Connection Error',
      subtitle: 'Please check your internet connection and try again',
      icon: Icons.wifi_off,
      buttonText: 'Retry',
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
      title: 'Permission Required',
      subtitle: 'Please grant $permission permission to continue',
      icon: Icons.lock_outline,
      buttonText: 'Grant Permission',
      onButtonPressed: onRequestPermission,
    );
  }
}
