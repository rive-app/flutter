/// Custom exception handler for SocketException (dart:io) and XmlHttpRequest
/// (web) http exceptions.
class HttpException implements Exception {
  HttpException(this.message, this.originalException);
  final String message;
  final Exception originalException;

  @override
  String toString() => 'HttpException' + message == null ? '' : ': $message';
}
