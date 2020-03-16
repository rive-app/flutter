import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sentry/sentry.dart';

// Sentry config
const _dsn = 'https://cd4c5a674f8e44f49203ce39d47c236c@sentry.io/3876713';
final _sentry = SentryClient(dsn: _dsn);

/// Configure logging options

void configureLogger() {
  // Set the log level from the LOG_LEVEL env variable
  final level = Platform.environment['LOG_LEVEL'];
  switch (level) {
    case 'debug':
      Logger.root.level = Level.ALL;
      break;
    case 'prod':
      Logger.root.level = Level.SEVERE;
      break;
    default:
      Logger.root.level = Level.INFO;
  }
  final disableSentryEnv = Platform.environment['DISABLE_SENTRY'];
  final disableSentry = disableSentryEnv != null;
  print('Sentry disabled status $disableSentry');

  // Print to the console and for SEVERE, write to sentry
  // When adding SEVERE logs, try to provide the error and stacktrace
  Logger.root.onRecord.listen((r) {
    print('${r.level.name}: ${r.time}: '
        '${r.message}: ${r.error ?? ''}: ${r.stackTrace ?? ''}');
    if (!disableSentry && r.level.compareTo(Level.SEVERE) >= 0) {
      try {
        print('Capturing to Sentry');
        _sentry.capture(
            event: Event(
          loggerName: r.loggerName,
          level: SeverityLevel.error,
          message: r.message,
          exception: r.error,
          stackTrace: r.stackTrace,
        ));
        // print('Sentry response: success: ${res.isSuccessful}, '
        //     'error: ß${res.error}');
      } on Exception catch (e) {
        // Not using log here to prevent cycles
        print('Sending report to sentry.io failed: $e');
      }
    }
  });
}

/// Waits a second before exiting to give loggers time to log
void sleepyExit(int code) =>
    Timer(const Duration(seconds: 1), () => exit(code));
