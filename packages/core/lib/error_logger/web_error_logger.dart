/// Web error logger goes to console

class ErrorLogger {
  static final ErrorLogger instance = ErrorLogger._();
  ErrorLogger._();

  Future<void> onError(Object e, StackTrace trace) {
    print('[Error]:\n$e');
    print('[Trace]:\n$trace');
    return Future.value();
  }
}
