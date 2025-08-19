import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _displayTimeFormat = DateFormat('HH:mm');
  static final DateFormat _displayDateTimeFormat =
      DateFormat('dd MMM yyyy, HH:mm');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  static String formatDisplayTime(DateTime date) {
    return _displayTimeFormat.format(date);
  }

  static String formatDisplayDateTime(DateTime date) {
    return _displayDateTimeFormat.format(date);
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isWithinWorkingHours(DateTime date) {
    return date.hour >= 9 && date.hour < 19;
  }
}

class StringUtils {
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String formatPhone(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if not present
    if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    } else if (!cleaned.startsWith('62')) {
      cleaned = '62$cleaned';
    }

    // Format: +62 xxx-xxxx-xxxx
    if (cleaned.length >= 10) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)}-${cleaned.substring(5, 9)}-${cleaned.substring(9)}';
    }

    return phone;
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class DistanceUtils {
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}

class ColorUtils {
  static const Map<String, int> statusColors = {
    'pending': 0xFFFFA726, // Orange
    'contacted': 0xFF42A5F5, // Blue
    'visited': 0xFF66BB6A, // Green
    'not_contacted': 0xFFEF5350, // Red
    'not_available': 0xFF9E9E9E, // Grey
  };

  static int getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? 0xFF9E9E9E;
  }
}
