import 'package:intl/intl.dart';

/// Utility class for handling Jakarta timezone (GMT+7) operations
class TimezoneUtils {
  static const Duration _jakartaOffset = Duration(hours: 7);

  /// Get current time in Jakarta timezone
  static DateTime nowInJakarta() {
    return DateTime.now().toUtc().add(_jakartaOffset);
  }

  /// Convert UTC DateTime to Jakarta timezone
  static DateTime utcToJakarta(DateTime utcDateTime) {
    if (!utcDateTime.isUtc) {
      // If not UTC, assume it's already in local timezone
      return utcDateTime;
    }
    return utcDateTime.add(_jakartaOffset);
  }

  /// Convert local DateTime to Jakarta timezone if needed
  static DateTime toJakarta(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(_jakartaOffset);
    }
    // Assume it's already in Jakarta timezone
    return dateTime;
  }

  /// Format DateTime in Jakarta timezone to Indonesian date format
  static String formatIndonesianDate(DateTime dateTime) {
    const monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final jakartaDate = toJakarta(dateTime);
    return '${jakartaDate.day} ${monthNames[jakartaDate.month]} ${jakartaDate.year}';
  }

  /// Format DateTime in Jakarta timezone to DD/MM/YYYY format
  static String formatDate(DateTime dateTime) {
    final jakartaDate = toJakarta(dateTime);
    return DateFormat('dd/MM/yyyy').format(jakartaDate);
  }

  /// Format DateTime in Jakarta timezone to HH:mm format
  static String formatTime(DateTime dateTime) {
    final jakartaDate = toJakarta(dateTime);
    return DateFormat('HH:mm').format(jakartaDate);
  }

  /// Format DateTime in Jakarta timezone to DD/MM/YYYY HH:mm format
  static String formatDateTime(DateTime dateTime) {
    final jakartaDate = toJakarta(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm').format(jakartaDate);
  }

  /// Format date for API submission (YYYY-MM-DD)
  static String formatDateForApi(DateTime dateTime) {
    final jakartaDate = toJakarta(dateTime);
    final year = jakartaDate.year.toString();
    final month = jakartaDate.month.toString().padLeft(2, '0');
    final day = jakartaDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parse API date string to Jakarta DateTime
  static DateTime parseApiDateTime(String dateTimeString) {
    try {
      final parsedTime = DateTime.parse(dateTimeString);
      return parsedTime.isUtc ? parsedTime.add(_jakartaOffset) : parsedTime;
    } catch (e) {
      print('Error parsing API DateTime: $e');
      return nowInJakarta();
    }
  }

  /// Get today's date in Jakarta timezone with time reset to start of day
  static DateTime todayInJakarta() {
    final now = nowInJakarta();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get Jakarta timezone offset string for display
  static String getTimezoneDisplay() {
    return 'GMT+7 (Jakarta Time)';
  }
}
