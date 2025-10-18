import 'package:wonwonw2/constants/api_constants.dart';

/// Utility class for input validation
class ValidationUtils {
  /// Validate email address
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(ApiConstants.emailPattern);
    return regex.hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    final regex = RegExp(ApiConstants.phonePattern);
    return regex.hasMatch(phone);
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    final regex = RegExp(ApiConstants.urlPattern);
    return regex.hasMatch(url);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Validate shop name
  static bool isValidShopName(String name) {
    return name.trim().length >= 2 && name.trim().length <= 100;
  }

  /// Validate shop description
  static bool isValidShopDescription(String description) {
    return description.trim().length >= 10 && description.trim().length <= 1000;
  }

  /// Validate shop address
  static bool isValidShopAddress(String address) {
    return address.trim().length >= 10 && address.trim().length <= 200;
  }

  /// Validate review comment
  static bool isValidReviewComment(String comment) {
    return comment.trim().length >= ApiConstants.minCommentLength && 
           comment.trim().length <= ApiConstants.maxCommentLength;
  }

  /// Validate forum topic title
  static bool isValidForumTitle(String title) {
    return title.trim().length >= ApiConstants.minTitleLength && 
           title.trim().length <= ApiConstants.maxTitleLength;
  }

  /// Validate forum topic content
  static bool isValidForumContent(String content) {
    return content.trim().length >= ApiConstants.minContentLength && 
           content.trim().length <= ApiConstants.maxContentLength;
  }

  /// Validate rating
  static bool isValidRating(double rating) {
    return rating >= ApiConstants.minRating && rating <= ApiConstants.maxRating;
  }

  /// Validate search query
  static bool isValidSearchQuery(String query) {
    return query.trim().length >= ApiConstants.minSearchLength;
  }

  /// Validate file size
  static bool isValidFileSize(int fileSize) {
    return fileSize <= ApiConstants.maxFileSize;
  }

  /// Validate image size
  static bool isValidImageSize(int fileSize) {
    return fileSize <= ApiConstants.maxImageSize;
  }

  /// Validate file type
  static bool isValidImageType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ApiConstants.allowedImageTypes.contains(extension);
  }

  /// Validate file type
  static bool isValidFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ApiConstants.allowedFileTypes.contains(extension);
  }

  /// Validate latitude
  static bool isValidLatitude(double latitude) {
    return latitude >= -90.0 && latitude <= 90.0;
  }

  /// Validate longitude
  static bool isValidLongitude(double longitude) {
    return longitude >= -180.0 && longitude <= 180.0;
  }

  /// Validate search radius
  static bool isValidSearchRadius(double radius) {
    return radius >= ApiConstants.minSearchRadius && 
           radius <= ApiConstants.maxSearchRadius;
  }

  /// Get validation error message
  static String getValidationErrorMessage(String field, dynamic value) {
    switch (field) {
      case 'email':
        return 'Please enter a valid email address';
      case 'password':
        return 'Password must be at least 8 characters with uppercase, lowercase, and number';
      case 'phone':
        return 'Please enter a valid phone number';
      case 'shopName':
        return 'Shop name must be between 2 and 100 characters';
      case 'shopDescription':
        return 'Shop description must be between 10 and 1000 characters';
      case 'shopAddress':
        return 'Shop address must be between 10 and 200 characters';
      case 'reviewComment':
        return 'Review comment must be between ${ApiConstants.minCommentLength} and ${ApiConstants.maxCommentLength} characters';
      case 'forumTitle':
        return 'Topic title must be between ${ApiConstants.minTitleLength} and ${ApiConstants.maxTitleLength} characters';
      case 'forumContent':
        return 'Topic content must be between ${ApiConstants.minContentLength} and ${ApiConstants.maxContentLength} characters';
      case 'rating':
        return 'Rating must be between ${ApiConstants.minRating} and ${ApiConstants.maxRating}';
      case 'searchQuery':
        return 'Search query must be at least ${ApiConstants.minSearchLength} characters';
      case 'fileSize':
        return 'File size must be less than ${ApiConstants.maxFileSize ~/ (1024 * 1024)}MB';
      case 'imageSize':
        return 'Image size must be less than ${ApiConstants.maxImageSize ~/ (1024 * 1024)}MB';
      case 'fileType':
        return 'File type not supported. Allowed types: ${ApiConstants.allowedImageTypes.join(', ')}';
      case 'latitude':
        return 'Latitude must be between -90 and 90';
      case 'longitude':
        return 'Longitude must be between -180 and 180';
      case 'searchRadius':
        return 'Search radius must be between ${ApiConstants.minSearchRadius} and ${ApiConstants.maxSearchRadius} km';
      default:
        return 'Invalid ${field}';
    }
  }

  /// Sanitize input string
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Sanitize HTML content
  static String sanitizeHtml(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  /// Validate and sanitize search query
  static String validateAndSanitizeSearchQuery(String query) {
    final sanitized = sanitizeString(query);
    if (sanitized.length < ApiConstants.minSearchLength) {
      throw ArgumentError('Search query too short');
    }
    return sanitized;
  }

  /// Validate coordinates
  static bool isValidCoordinates(double latitude, double longitude) {
    return isValidLatitude(latitude) && isValidLongitude(longitude);
  }

  /// Validate pagination parameters
  static bool isValidPagination(int page, int limit) {
    return page >= 0 && limit > 0 && limit <= ApiConstants.maxPageSize;
  }

  /// Normalize pagination parameters
  static Map<String, int> normalizePagination(int page, int limit) {
    return {
      'page': page < 0 ? 0 : page,
      'limit': limit <= 0 ? ApiConstants.defaultPageSize : 
               limit > ApiConstants.maxPageSize ? ApiConstants.maxPageSize : limit,
    };
  }
}
