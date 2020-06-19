/// Datetime extensions
extension DateExtensions on DateTime {
  /// Pretty pretty 'XX time ago' from present time
  String get howLongAgo {
    final durationElapsed = DateTime.now().difference(this);

    // Pluarize English words if the interval > 1
    String pluralize(int interval, String singular) {
      final output = (interval == 1) ? singular : singular + 's';
      return '$interval $output ago';
    }

    if (durationElapsed.inSeconds <= 0) {
      // This should never happen, as this is in the future
      return 'just now';
    }
    if (durationElapsed.inSeconds < 60) {
      return pluralize(durationElapsed.inSeconds, 'second');
    } else if (durationElapsed.inMinutes < 60) {
      return pluralize(durationElapsed.inMinutes, 'minute');
    } else if (durationElapsed.inHours < 24) {
      return pluralize(durationElapsed.inHours, 'hour');
    } else if (durationElapsed.inDays < 7) {
      return pluralize(durationElapsed.inDays, 'day');
    } else if (durationElapsed.inDays < 30) {
      return pluralize(durationElapsed.inDays ~/ 7, 'week');
    } else if (durationElapsed.inDays < 365) {
      return pluralize(durationElapsed.inDays ~/ 30, 'month');
    } else {
      return pluralize(durationElapsed.inDays ~/ 365, 'year');
    }
  }

  String get monthName {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'Novemver';
      case 12:
        return 'December';
      default:
        throw RangeError("Month out of range [1..12]: $month");
    }
  }

  String get shortMonthName {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        throw RangeError("Month out of range [1..12]: $month");
    }
  }

  // Returns a description of this date in the format "MMM D, YYYY"
  // e.g. Sep 26, 1989
  String get shortDescription => '$shortMonthName $day, $year';
  // Returns a description of this date in the format "MMMM D, YYYY"
  // e.g. September 26, 1989
  String get description => '$monthName $day, $year';

}
