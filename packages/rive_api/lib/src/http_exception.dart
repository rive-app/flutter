/// Custom exception handler for SocketException (dart:io) and XmlHttpRequest
/// (web) http exceptions.
class HttpException implements Exception {
  final String message;
  final Exception originalException;

  HttpException(this.message, this.originalException);

  @override
  String toString() {
    if (message == null) return "HttpException";
    return "HttpException: $message";
  }
}
