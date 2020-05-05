import 'native_error_logger.dart'
    if (dart.library.html) 'web_error_logger.dart';
import 'package:meta/meta.dart';

@immutable
class ErrorLogUser {
  final String username;
  final String id;

  const ErrorLogUser({
    @required this.username,
    @required this.id,
  });
}

enum CrumbType {
  defaultType,
  http,
  navigation,
}

enum CrumbSeverity {
  fatal,
  error,
  warning,
  info,
  debug,
}

class ErrorBreadcrumb {
  final String message;
  final DateTime timestamp;
  final String category;
  final CrumbType type;
  final CrumbSeverity severity;
  final Map<String, String> data;

  const ErrorBreadcrumb({
    this.category,
    this.message,
    this.type,
    this.data,
    this.severity,
    this.timestamp,
  });
}

abstract class ErrorLogger {
  ErrorLogger();

  @protected
  final breadcrumbs = List<ErrorBreadcrumb>();

  /// Use this to track the currently logged in user.
  ErrorLogUser get user;
  set user(ErrorLogUser value);

  /// Adds context to the current set of operations. These will only be reported
  /// if an error occurs.
  void dropCrumb({
    String category,
    String message,
    CrumbType type,
    CrumbSeverity severity,
    Map<String, String> data,
  }) {
    breadcrumbs.add(
      ErrorBreadcrumb(
        category: category,
        message: message,
        type: type,
        severity: severity,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> reportException(Object e, StackTrace trace);
  static ErrorLogger get instance => getErrorLogger();
}
