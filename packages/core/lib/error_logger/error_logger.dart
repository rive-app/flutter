import 'native_error_logger.dart' if (dart.library.html) 'web_error_logger.dart'
    as errorLogger;

Future<void> onError(Object e, StackTrace trace) =>
    errorLogger.ErrorLogger.instance.onError(e, trace);
