/// API Constants for Wonwonw2 App
/// 
/// This file contains all API-related constants including endpoints,
/// timeouts, retry counts, and other configuration values.

class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://wonwonw2-default-rtdb.firebaseio.com';
  static const String firestoreUrl = 'https://firestore.googleapis.com/v1';
  static const String authUrl = 'https://identitytoolkit.googleapis.com/v1';
  
  // API Endpoints
  static const String shopsEndpoint = '/shops';
  static const String usersEndpoint = '/users';
  static const String reviewsEndpoint = '/reviews';
  static const String forumTopicsEndpoint = '/forum_topics';
  static const String forumRepliesEndpoint = '/forum_replies';
  static const String reportsEndpoint = '/reports';
  static const String notificationsEndpoint = '/notifications';
  static const String categoriesEndpoint = '/categories';
  static const String subServicesEndpoint = '/sub_services';
  
  // Authentication Endpoints
  static const String loginEndpoint = '/accounts:signInWithPassword';
  static const String registerEndpoint = '/accounts:signUp';
  static const String logoutEndpoint = '/accounts:signOut';
  static const String refreshTokenEndpoint = '/token';
  static const String resetPasswordEndpoint = '/accounts:sendOobCode';
  static const String verifyEmailEndpoint = '/accounts:sendOobCode';
  
  // Admin Endpoints
  static const String adminDashboardEndpoint = '/admin/dashboard';
  static const String adminShopsEndpoint = '/admin/shops';
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminReportsEndpoint = '/admin/reports';
  static const String adminAnalyticsEndpoint = '/admin/analytics';
  static const String adminSettingsEndpoint = '/admin/settings';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration imageLoadTimeout = Duration(seconds: 15);
  
  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration exponentialBackoffBase = Duration(seconds: 1);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int forumPageSize = 15;
  static const int reviewsPageSize = 10;
  
  // Cache Configuration
  static const Duration shopCacheDuration = Duration(hours: 1);
  static const Duration userCacheDuration = Duration(minutes: 30);
  static const Duration forumCacheDuration = Duration(minutes: 15);
  static const Duration adminCacheDuration = Duration(minutes: 5);
  static const Duration imageCacheDuration = Duration(days: 7);
  
  // Rate Limiting
  static const int generalRateLimit = 100; // requests per minute
  static const int authRateLimit = 10; // requests per minute
  static const int uploadRateLimit = 5; // requests per minute
  static const int adminRateLimit = 50; // requests per minute
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx', 'txt'];
  
  // Search Configuration
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;
  static const int searchDebounceMs = 300;
  static const int searchTimeoutMs = 5000;
  
  // Location Configuration
  static const double defaultSearchRadius = 10.0; // kilometers
  static const double maxSearchRadius = 50.0; // kilometers
  static const double minSearchRadius = 0.5; // kilometers
  static const int maxNearbyShops = 20;
  
  // Review Configuration
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int minCommentLength = 10;
  static const int maxCommentLength = 1000;
  static const int maxReviewsPerUser = 1; // per shop
  
  // Forum Configuration
  static const int minTitleLength = 5;
  static const int maxTitleLength = 100;
  static const int minContentLength = 10;
  static const int maxContentLength = 5000;
  static const int maxTagsPerTopic = 5;
  static const int maxRepliesPerTopic = 1000;
  
  // Notification Configuration
  static const int maxNotificationLength = 200;
  static const Duration notificationDisplayDuration = Duration(seconds: 5);
  static const int maxNotificationsPerUser = 100;
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  static const String unauthorizedErrorMessage = 'You are not authorized to perform this action.';
  static const String notFoundErrorMessage = 'The requested resource was not found.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unexpected error occurred. Please try again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful';
  static const String registerSuccessMessage = 'Registration successful';
  static const String logoutSuccessMessage = 'Logout successful';
  static const String shopAddedSuccessMessage = 'Shop added successfully';
  static const String shopUpdatedSuccessMessage = 'Shop updated successfully';
  static const String reviewAddedSuccessMessage = 'Review added successfully';
  static const String topicCreatedSuccessMessage = 'Topic created successfully';
  static const String replyAddedSuccessMessage = 'Reply added successfully';
  
  // Validation Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String urlPattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  
  // Default Values
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'THB';
  static const String defaultTimeZone = 'Asia/Bangkok';
  static const String defaultDateFormat = 'dd/MM/yyyy';
  static const String defaultTimeFormat = 'HH:mm';
  static const String defaultDateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Feature Flags
  static const bool enableCaching = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  
  // Development Configuration
  static const bool enableDebugLogging = true;
  static const bool enableVerboseLogging = false;
  static const bool enableNetworkLogging = true;
  static const bool enablePerformanceLogging = true;
  
  // Production Configuration
  static const bool productionMode = false; // Set to true for production
  static const String productionBaseUrl = 'https://api.wonwonw2.com';
  static const String stagingBaseUrl = 'https://staging-api.wonwonw2.com';
  
  // API Keys (These should be stored securely in production)
  static const String firebaseApiKey = 'AIzaSyBvQvQvQvQvQvQvQvQvQvQvQvQvQvQvQvQ';
  static const String googleMapsApiKey = 'AIzaSyBvQvQvQvQvQvQvQvQvQvQvQvQvQvQvQvQ';
  static const String analyticsApiKey = 'UA-XXXXXXXXX-X';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Wonwonw2/1.0.0',
  };
  
  static const Map<String, String> authHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer {token}',
  };
  
  // Query Parameters
  static const Map<String, dynamic> defaultQueryParams = {
    'limit': defaultPageSize,
    'offset': 0,
    'sort': 'createdAt',
    'order': 'desc',
  };
  
  // Response Codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int noContentCode = 204;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int conflictCode = 409;
  static const int unprocessableEntityCode = 422;
  static const int tooManyRequestsCode = 429;
  static const int internalServerErrorCode = 500;
  static const int serviceUnavailableCode = 503;
}
