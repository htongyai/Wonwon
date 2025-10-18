import 'package:intl/intl.dart';
import 'package:wonwonw2/constants/api_constants.dart';

/// Utility class for date and time operations
class DateUtils {
  /// Format date according to app settings
  static String formatDate(DateTime date) {
    return DateFormat(ApiConstants.defaultDateFormat).format(date);
  }

  /// Format time according to app settings
  static String formatTime(DateTime time) {
    return DateFormat(ApiConstants.defaultTimeFormat).format(time);
  }

  /// Format date and time according to app settings
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(ApiConstants.defaultDateTimeFormat).format(dateTime);
  }

  /// Format date for display in lists
  static String formatDateForList(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Format date for relative time display
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }

  /// Format date for API requests
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format datetime for API requests
  static String formatDateTimeForApi(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSSZ').format(dateTime);
  }

  /// Parse date from API response
  static DateTime? parseDateFromApi(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week
  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get end of week
  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = getStartOfWeek(now);
    final endOfWeek = getEndOfWeek(now);
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  /// Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is this year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Get age in years
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get time zone offset
  static Duration getTimeZoneOffset() {
    return DateTime.now().timeZoneOffset;
  }

  /// Convert to UTC
  static DateTime toUtc(DateTime dateTime) {
    return dateTime.toUtc();
  }

  /// Convert from UTC
  static DateTime fromUtc(DateTime dateTime) {
    return dateTime.toLocal();
  }

  /// Get current timestamp
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Convert timestamp to DateTime
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Format duration
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format business hours
  static String formatBusinessHours(String hours) {
    if (hours.isEmpty || hours.toLowerCase() == 'closed') {
      return 'Closed';
    }
    
    try {
      final parts = hours.split('-');
      if (parts.length == 2) {
        final open = parts[0].trim();
        final close = parts[1].trim();
        return '$open - $close';
      }
    } catch (e) {
      // If parsing fails, return original string
    }
    
    return hours;
  }

  /// Check if business is open
  static bool isBusinessOpen(String hours) {
    if (hours.isEmpty || hours.toLowerCase() == 'closed') {
      return false;
    }
    
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      final parts = hours.split('-');
      if (parts.length == 2) {
        final open = parts[0].trim();
        final close = parts[1].trim();
        
        return currentTime.compareTo(open) >= 0 && currentTime.compareTo(close) <= 0;
      }
    } catch (e) {
      // If parsing fails, assume closed
    }
    
    return false;
  }

  /// Get day of week name
  static String getDayOfWeekName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get short day of week name
  static String getShortDayOfWeekName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Get short month name
  static String getShortMonthName(DateTime date) {
    return DateFormat('MMM').format(date);
  }
}
