import 'package:flutter_test/flutter_test.dart';
import 'package:wonwonw2/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    group('Date Formatting', () {
      test('should format date correctly', () {
        final date = DateTime(2023, 12, 25);
        expect(DateUtils.formatDate(date), '25/12/2023');
      });

      test('should format time correctly', () {
        final time = DateTime(2023, 12, 25, 14, 30);
        expect(DateUtils.formatTime(time), '14:30');
      });

      test('should format date and time correctly', () {
        final dateTime = DateTime(2023, 12, 25, 14, 30);
        expect(DateUtils.formatDateTime(dateTime), '25/12/2023 14:30');
      });
    });

    group('Relative Time Formatting', () {
      test('should format relative time for today', () {
        final now = DateTime.now();
        expect(DateUtils.formatDateForList(now), 'Today');
      });

      test('should format relative time for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateUtils.formatDateForList(yesterday), 'Yesterday');
      });

      test('should format relative time for days ago', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        expect(DateUtils.formatDateForList(threeDaysAgo), '3 days ago');
      });

      test('should format relative time for weeks ago', () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        expect(DateUtils.formatDateForList(twoWeeksAgo), '2 weeks ago');
      });

      test('should format relative time for months ago', () {
        final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
        expect(DateUtils.formatDateForList(twoMonthsAgo), '2 months ago');
      });

      test('should format relative time for years ago', () {
        final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
        expect(DateUtils.formatDateForList(twoYearsAgo), '2 years ago');
      });
    });

    group('Date Range Operations', () {
      test('should get start of day', () {
        final date = DateTime(2023, 12, 25, 14, 30, 45);
        final startOfDay = DateUtils.getStartOfDay(date);
        expect(startOfDay.hour, 0);
        expect(startOfDay.minute, 0);
        expect(startOfDay.second, 0);
        expect(startOfDay.millisecond, 0);
      });

      test('should get end of day', () {
        final date = DateTime(2023, 12, 25, 14, 30, 45);
        final endOfDay = DateUtils.getEndOfDay(date);
        expect(endOfDay.hour, 23);
        expect(endOfDay.minute, 59);
        expect(endOfDay.second, 59);
        expect(endOfDay.millisecond, 999);
      });

      test('should get start of week', () {
        final date = DateTime(2023, 12, 25); // Monday
        final startOfWeek = DateUtils.getStartOfWeek(date);
        expect(startOfWeek.weekday, 1); // Monday
      });

      test('should get start of month', () {
        final date = DateTime(2023, 12, 25);
        final startOfMonth = DateUtils.getStartOfMonth(date);
        expect(startOfMonth.day, 1);
        expect(startOfMonth.month, 12);
        expect(startOfMonth.year, 2023);
      });
    });

    group('Date Checks', () {
      test('should check if date is today', () {
        final now = DateTime.now();
        expect(DateUtils.isToday(now), true);
        
        final yesterday = now.subtract(const Duration(days: 1));
        expect(DateUtils.isToday(yesterday), false);
      });

      test('should check if date is yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateUtils.isYesterday(yesterday), true);
        
        final today = DateTime.now();
        expect(DateUtils.isYesterday(today), false);
      });

      test('should check if date is this month', () {
        final now = DateTime.now();
        expect(DateUtils.isThisMonth(now), true);
        
        final lastMonth = DateTime(now.year, now.month - 1, now.day);
        expect(DateUtils.isThisMonth(lastMonth), false);
      });

      test('should check if date is this year', () {
        final now = DateTime.now();
        expect(DateUtils.isThisYear(now), true);
        
        final lastYear = DateTime(now.year - 1, now.month, now.day);
        expect(DateUtils.isThisYear(lastYear), false);
      });
    });

    group('Age Calculation', () {
      test('should calculate age correctly', () {
        final birthDate = DateTime(1990, 1, 1);
        final currentDate = DateTime(2023, 1, 1);
        // Mock current time for testing
        expect(DateUtils.getAge(birthDate), greaterThan(30));
      });
    });

    group('Timestamp Operations', () {
      test('should get current timestamp', () {
        final timestamp = DateUtils.getCurrentTimestamp();
        expect(timestamp, greaterThan(0));
      });

      test('should convert timestamp to DateTime', () {
        final timestamp = 1672531200000; // 2023-01-01 00:00:00 UTC
        final dateTime = DateUtils.fromTimestamp(timestamp);
        expect(dateTime.year, 2023);
        expect(dateTime.month, 1);
        expect(dateTime.day, 1);
      });
    });

    group('Duration Formatting', () {
      test('should format duration correctly', () {
        expect(DateUtils.formatDuration(const Duration(seconds: 30)), '30s');
        expect(DateUtils.formatDuration(const Duration(minutes: 5, seconds: 30)), '5m 30s');
        expect(DateUtils.formatDuration(const Duration(hours: 2, minutes: 30)), '2h 30m');
        expect(DateUtils.formatDuration(const Duration(days: 1, hours: 2)), '1d 2h');
      });
    });

    group('Business Hours', () {
      test('should format business hours correctly', () {
        expect(DateUtils.formatBusinessHours('09:00-17:00'), '09:00 - 17:00');
        expect(DateUtils.formatBusinessHours('closed'), 'Closed');
        expect(DateUtils.formatBusinessHours(''), 'Closed');
      });

      test('should check if business is open', () {
        // This test might be flaky due to time dependency
        expect(DateUtils.isBusinessOpen('closed'), false);
        expect(DateUtils.isBusinessOpen(''), false);
      });
    });

    group('Day and Month Names', () {
      test('should get day of week name', () {
        final monday = DateTime(2023, 12, 25); // Monday
        expect(DateUtils.getDayOfWeekName(monday), 'Monday');
      });

      test('should get short day of week name', () {
        final monday = DateTime(2023, 12, 25); // Monday
        expect(DateUtils.getShortDayOfWeekName(monday), 'Mon');
      });

      test('should get month name', () {
        final december = DateTime(2023, 12, 25);
        expect(DateUtils.getMonthName(december), 'December');
      });

      test('should get short month name', () {
        final december = DateTime(2023, 12, 25);
        expect(DateUtils.getShortMonthName(december), 'Dec');
      });
    });
  });
}
