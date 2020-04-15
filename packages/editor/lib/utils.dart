/// Set of Dart and Flutter utility functions and extensions

// String extensions
extension StringExtensions on String {
  /// Capitalize the first letter of a string
  String get capsFirst {
    assert(length > 0);
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

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
}
