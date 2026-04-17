library shared;

// Firebase
export 'firebase_options.dart';

// Config
export 'config/web_config.dart';

// Constants
export 'constants/app_constants.dart';
export 'constants/api_constants.dart';
export 'constants/app_colors.dart';
export 'constants/design_tokens.dart';
export 'constants/map_constants.dart';
export 'constants/responsive_breakpoints.dart';
export 'constants/app_text_styles.dart';

// Models
export 'models/user.dart';
export 'models/repair_shop.dart';
export 'models/repair_category.dart';
export 'models/repair_record.dart';
export 'models/review.dart';
export 'models/forum_topic.dart';
export 'models/forum_reply.dart';
export 'models/notification.dart';
export 'models/service_category.dart';
export 'models/repair_sub_service.dart';
export 'models/shop_stats.dart';

// Theme
export 'theme/app_theme.dart';

// Localization
export 'localization/app_localizations.dart';
export 'localization/app_localizations_wrapper.dart';

// Utils
export 'utils/app_logger.dart';
export 'utils/performance_utils.dart';
export 'utils/error_handler.dart';
export 'utils/validation_utils.dart';
export 'utils/date_utils.dart';
export 'utils/responsive_size.dart';
export 'utils/asset_helpers.dart';
export 'utils/icon_helper.dart';
export 'utils/hours_formatter.dart';

// Services
export 'services/auth_service.dart';
export 'services/auth_manager.dart';
export 'services/auth_state_service.dart';
export 'services/shop_service.dart';
export 'services/firebase_shop_service.dart';
export 'services/user_service.dart';
export 'services/report_service.dart';
export 'services/review_service.dart';
export 'services/forum_service.dart';
export 'services/notification_service.dart';
export 'services/saved_shop_service.dart';
export 'services/location_service.dart';
export 'services/activity_service.dart';
export 'services/analytics_service.dart';
export 'services/content_management_service.dart';
export 'services/error_handling_service.dart';
export 'services/performance_monitor.dart';
export 'services/service_manager.dart';
export 'services/service_providers.dart';
export 'services/cache_service.dart';
export 'services/version_service.dart';
export 'services/resource_cache_manager.dart';
export 'services/shop_analytics_service.dart';
export 'services/google_maps_link_service.dart';

// State
export 'state/app_state_manager.dart';

// Mixins
export 'mixins/auth_state_mixin.dart';
export 'mixins/widget_disposal_mixin.dart';

// Widgets (shared)
export 'widgets/optimized_screen.dart';
export 'widgets/optimized_widget.dart';
export 'widgets/optimized_image.dart';
export 'widgets/error_boundary.dart';
export 'widgets/common/empty_state_widget.dart';
export 'widgets/common/loading_widget.dart';
export 'widgets/common/shimmer_loading.dart';
export 'widgets/performance_loading_widget.dart';
export 'widgets/force_update_checker.dart';
