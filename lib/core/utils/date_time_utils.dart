/// Utilities for handling GTFS time format.
///
/// GTFS uses HH:MM:SS where HH can exceed 24 (e.g. 25:30:00 = 1:30 AM next day).
/// The "service day" typically starts around 4:00 AM and extends past midnight.
class DateTimeUtils {
  DateTimeUtils._();

  /// Parse a GTFS time string (HH:MM:SS) into total seconds since midnight.
  /// Handles times > 24:00:00.
  static int parseGtfsTime(String timeStr) {
    final parts = timeStr.trim().split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid GTFS time format: $timeStr');
    }
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    return hours * 3600 + minutes * 60 + seconds;
  }

  /// Convert total seconds since midnight to a display string (HH:MM).
  /// Normalizes times > 24h (e.g. 25:30 -> 01:30).
  static String formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600) % 24;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Get the current time as total seconds since midnight.
  static int currentTimeAsSeconds() {
    final now = DateTime.now();
    return now.hour * 3600 + now.minute * 60 + now.second;
  }

  /// Determine the GTFS "service date" for the current moment.
  /// If it's before 4:00 AM, the service date is yesterday.
  static DateTime getServiceDate([DateTime? now]) {
    final dateTime = now ?? DateTime.now();
    if (dateTime.hour < 4) {
      return DateTime(dateTime.year, dateTime.month, dateTime.day - 1);
    }
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Parse a GTFS date string (YYYYMMDD) to DateTime.
  static DateTime parseGtfsDate(String dateStr) {
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    return DateTime(year, month, day);
  }

  /// Format a DateTime as GTFS date string (YYYYMMDD).
  static String toGtfsDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the weekday name used in GTFS calendar (monday, tuesday, etc.)
  static String weekdayName(int weekday) {
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return names[weekday - 1];
  }

  /// Calculate minutes until arrival from total seconds.
  static int minutesUntil(int arrivalSeconds) {
    final now = currentTimeAsSeconds();
    final diff = arrivalSeconds - now;
    if (diff < 0) return 0;
    return diff ~/ 60;
  }
}
