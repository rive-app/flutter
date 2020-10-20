/// Native error logger usies sentry

import 'package:sentry/sentry.dart';
import 'package:utilities/sentry.dart';

import 'error_logger.dart';

bool get isInDebugMode {
  bool inDebugMode = false;

  // Assert expressions are only evaluated during development. They are ignored
  // in production. Therefore, this code only sets `inDebugMode` to true
  // in a development environment.
  assert(inDebugMode = true);

  return inDebugMode;
}

String _crumbTypeToString(CrumbType type) {
  switch (type) {
    case CrumbType.defaultType:
      return 'default';
    case CrumbType.http:
      return 'http';
    case CrumbType.navigation:
      return 'navigation';
  }
  return type.toString();
}

SeverityLevel _crumbSeverityToSentry(CrumbSeverity severity) {
  switch (severity) {
    case CrumbSeverity.fatal:
      return SeverityLevel.fatal;
    case CrumbSeverity.error:
      return SeverityLevel.error;
    case CrumbSeverity.warning:
      return SeverityLevel.warning;
    case CrumbSeverity.info:
      return SeverityLevel.info;
    case CrumbSeverity.debug:
      return SeverityLevel.debug;
  }
  return null;
}

class NativeErrorLogger extends ErrorLogger {
  static final ErrorLogger instance = NativeErrorLogger._();

  ErrorLogUser _user;
  NativeErrorLogger._();

  @override
  ErrorLogUser get user => _user;

  @override
  set user(ErrorLogUser value) {
    if (_user == value) {
      return;
    }
    _user = value;
    sentryClient.userContext = User(username: value.username, id: value.id);
  }

  @override
  Future<void> reportException(Object e, StackTrace trace) async {
    if (isInDebugMode) {
      print('[Error]:\n$e');
      print('[Trace]:\n$trace');
      return;
    } else {
      print('Logging to sentry the current error $e');
      final Event event = Event(
        exception: e,
        stackTrace: trace,
        breadcrumbs: breadcrumbs
            .map(
              (crumb) => Breadcrumb(
                crumb.message,
                crumb.timestamp,
                category: crumb.category,
                type: _crumbTypeToString(crumb.type),
                level: _crumbSeverityToSentry(crumb.severity),
                data: crumb.data,
              ),
            )
            .toList(growable: false),
      );
      final response = await sentryClient.capture(event: event);
      if (response.isSuccessful) {
        print('Sent to Sentry! ${response.eventId}');
      } else {
        print('Sentry report failed ${response.error}');
      }
    }
  }
}

ErrorLogger getErrorLogger() => NativeErrorLogger.instance;
