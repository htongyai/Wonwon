import 'package:flutter/material.dart';
import 'package:shared/localization/app_localizations_wrapper.dart';

/// Utility class for formatting shop hours consistently throughout the app
class HoursFormatter {
  /// Formats shop hours string to display consistently
  /// Handles various input formats and returns properly formatted time ranges
  static String formatHours(String? hours, BuildContext context) {
    if (hours == null || hours.isEmpty) {
      return 'day_closed'.tr(context);
    }

    // Handle already formatted "Closed" status
    if (hours.toLowerCase() == 'closed') {
      return 'day_closed'.tr(context);
    }

    // Clean up the hours string
    String cleanHours = hours.trim();

    // Already displayed as "24 hours" / "Open 24h" (case-insensitive)
    final lower = cleanHours.toLowerCase();
    if (lower == '24 hours' ||
        lower == '24h' ||
        lower == 'open 24 hours' ||
        lower == 'open 24h' ||
        lower == '24/7') {
      return 'open_24_hours'.tr(context);
    }

    // Handle various formats and ensure proper display
    if (cleanHours.contains('-')) {
      // Split on dash and clean up each part
      final parts = cleanHours.split('-');
      if (parts.length == 2) {
        final openTime = parts[0].trim();
        final closeTime = parts[1].trim();

        // Format times consistently
        final formattedOpen = _formatTime(openTime);
        final formattedClose = _formatTime(closeTime);

        // Detect 24-hour operation: open time equals close time (e.g.
        // "00:00-00:00" or "12:00 AM - 12:00 AM"), or explicit full-day
        // span (00:00-23:59).
        if (_isTwentyFourHours(formattedOpen, formattedClose)) {
          return 'open_24_hours'.tr(context);
        }

        return '$formattedOpen - $formattedClose';
      }
    }

    // Return as-is if no dash found or formatting fails
    return cleanHours.isNotEmpty ? cleanHours : 'day_closed'.tr(context);
  }

  /// Returns true when [open] and [close] describe a 24-hour-a-day
  /// operation. Accepts both "00:00-00:00" (same time) and
  /// "00:00-23:59" (full-day span).
  static bool _isTwentyFourHours(String open, String close) {
    int? openMin;
    int? closeMin;
    try {
      openMin = _parseTime(open);
      closeMin = _parseTime(close);
    } catch (_) {
      return false;
    }
    // Same open and close = treated as 24 hours (common convention).
    if (openMin == closeMin) return true;
    // 00:00 open and 23:59 close = effectively 24 hours.
    if (openMin == 0 && closeMin == 23 * 60 + 59) return true;
    return false;
  }

  /// Formats individual time strings to HH:MM format
  static String _formatTime(String time) {
    // Remove any extra spaces
    String cleanTime = time.trim();

    // If already in HH:MM format, return as-is
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(cleanTime)) {
      return cleanTime;
    }

    // If in H:MM format, pad with zero
    if (RegExp(r'^\d:\d{2}$').hasMatch(cleanTime)) {
      return '0$cleanTime';
    }

    // If in HHMM format, add colon
    if (RegExp(r'^\d{3,4}$').hasMatch(cleanTime)) {
      if (cleanTime.length == 3) {
        return '${cleanTime.substring(0, 1)}:${cleanTime.substring(1)}';
      } else if (cleanTime.length == 4) {
        return '${cleanTime.substring(0, 2)}:${cleanTime.substring(2)}';
      }
    }

    // If in H.MM or HH.MM format, replace dot with colon
    if (cleanTime.contains('.')) {
      cleanTime = cleanTime.replaceAll('.', ':');
      return _formatTime(
        cleanTime,
      ); // Recursive call to handle the converted format
    }

    // Return as-is if no recognized format
    return cleanTime;
  }

  /// Formats hours map for display in admin interfaces
  /// Returns a formatted string representation of all hours
  static String formatHoursMap(
    Map<String, String> hours,
    BuildContext context,
  ) {
    if (hours.isEmpty) {
      return 'no_hours_set'.tr(context);
    }

    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayNames = [
      'day_monday'.tr(context),
      'day_tuesday'.tr(context),
      'day_wednesday'.tr(context),
      'day_thursday'.tr(context),
      'day_friday'.tr(context),
      'day_saturday'.tr(context),
      'day_sunday'.tr(context),
    ];

    List<String> formattedHours = [];
    for (int i = 0; i < days.length; i++) {
      final dayHours = hours[days[i]];
      final formattedTime = formatHours(dayHours, context);
      formattedHours.add('${dayNames[i]}: $formattedTime');
    }

    return formattedHours.join('\n');
  }

  /// Gets the current day's hours in formatted form
  static String getTodaysHours(
    Map<String, String> hours,
    BuildContext context,
  ) {
    final now = DateTime.now();
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayKey = dayKeys[now.weekday - 1]; // weekday is 1-7, array is 0-6

    final todayHours = hours[todayKey];
    return formatHours(todayHours, context);
  }

  /// Checks if a shop is currently open based on current time and hours
  static bool isShopOpen(Map<String, String> hours) {
    final now = DateTime.now();
    final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayKey = dayKeys[now.weekday - 1];

    final todayHours = hours[todayKey];
    if (todayHours == null || todayHours.toLowerCase() == 'closed') {
      return false;
    }

    // Explicit 24-hour strings always count as open.
    final lower = todayHours.toLowerCase();
    if (lower == '24 hours' ||
        lower == '24h' ||
        lower == 'open 24 hours' ||
        lower == 'open 24h' ||
        lower == '24/7') {
      return true;
    }

    if (todayHours.contains('-')) {
      final parts = todayHours.split('-');
      if (parts.length == 2) {
        try {
          final openTime = _parseTime(parts[0].trim());
          final closeTime = _parseTime(parts[1].trim());
          // Same open/close time = 24 hours (always open).
          if (openTime == closeTime) return true;
          final currentTime = now.hour * 60 + now.minute;

          // Handle "past midnight" shifts (e.g. 18:00-02:00).
          if (closeTime < openTime) {
            return currentTime >= openTime || currentTime < closeTime;
          }
          return currentTime >= openTime && currentTime <= closeTime;
        } catch (e) {
          return false;
        }
      }
    }

    return false;
  }

  /// Parses time string to minutes since midnight
  static int _parseTime(String timeStr) {
    final formattedTime = _formatTime(timeStr);
    final parts = formattedTime.split(':');
    if (parts.length == 2) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    }
    throw FormatException('Invalid time format: $timeStr');
  }
}
