import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime timestamp) {
    try {
      return DateFormat('hh:mm a', 'ar').format(timestamp);
    } catch (e) {
      return '';
    }
  }

  static String formatChatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final isToday = _isSameDay(timestamp, now);

    if (isToday) {
      return DateFormat('hh:mm a', 'ar').format(timestamp);
    }

    final diffDays = now.difference(timestamp).inDays;
    if (diffDays == 1) return 'أمس';
    if (diffDays < 7) {
      return DateFormat('EEEE', 'ar').format(timestamp);
    }

    return DateFormat('d MMM', 'ar').format(timestamp);
  }

  static String getDayLabel(DateTime timestamp) {
    final now = DateTime.now();

    if (_isSameDay(timestamp, now)) return 'اليوم';

    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(timestamp, yesterday)) return 'أمس';

    final diffDays = now.difference(timestamp).inDays;
    if (diffDays < 7) {
      return DateFormat('EEEE', 'ar').format(timestamp);
    }

    return DateFormat('d MMMM yyyy', 'ar').format(timestamp);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
