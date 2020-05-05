import 'error_logger.dart';

/// Web error logger goes to console

class WebErrorLogger extends ErrorLogger {
  static final ErrorLogger instance = WebErrorLogger._();
  WebErrorLogger._();

  Future<void> reportException(Object e, StackTrace trace) {
    print('[Error]:\n$e');
    print('[Trace]:\n$trace');
    return Future.value();
  }

  @override
  ErrorLogUser user;
}

ErrorLogger makeErrorLogger() => WebErrorLogger.instance;
