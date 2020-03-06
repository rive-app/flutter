import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

bool get isInDebugMode {
  // TODO: move this into an environment variable.
  bool inDebugMode = true;

  // Assert expressions are only evaluated during development. They are ignored
  // in production. Therefore, this code only sets `inDebugMode` to true
  // in a development environment.
  assert(inDebugMode = true);

  return inDebugMode;
}

class ErrorLogger {
  static final _sentry = SentryClient(
      dsn: "https://1ea8934c37fb4d948c7b057827db4e4d@sentry.io/3764728");
  static final ErrorLogger instance = ErrorLogger._();

  ErrorLogger._();


  Future<void> onError(Object e, StackTrace trace) async {
    if (isInDebugMode) {
      debugPrint('Error: $e');
      print('$trace');
      return;
    } else {
      debugPrint("Logging to sentry the current error $e");
      final response =
          await _sentry.captureException(exception: e, stackTrace: trace);
      if (response.isSuccessful) {
        print('Sent to Sentry! ${response.eventId}');
      } else {
        print('Sentry report failed ${response.error}');
      }
    }
  }
}
