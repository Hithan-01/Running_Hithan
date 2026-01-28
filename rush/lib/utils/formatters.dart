import 'package:intl/intl.dart';

class Formatters {
  // Distance formatting
  static String distance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    double km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  static String distanceKm(double km) {
    return '${km.toStringAsFixed(2)} km';
  }

  // Duration formatting
  static String duration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String durationWords(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  // Pace formatting (minutes per km)
  static String pace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm.isNaN) {
      return '--:--';
    }
    int minutes = paceMinPerKm.floor();
    int seconds = ((paceMinPerKm - minutes) * 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  static String paceWithUnit(double paceMinPerKm) {
    return '${pace(paceMinPerKm)} /km';
  }

  // Date formatting
  static String date(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  static String dateShort(DateTime dateTime) {
    return DateFormat('d MMM').format(dateTime);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
  }

  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} dias';
    } else {
      return date(dateTime);
    }
  }

  // XP formatting
  static String xp(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K XP';
    }
    return '$amount XP';
  }

  // Number formatting with commas
  static String number(int value) {
    return NumberFormat('#,###').format(value);
  }

  // Percentage
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  // Ordinal (1st, 2nd, 3rd, etc.)
  static String ordinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
