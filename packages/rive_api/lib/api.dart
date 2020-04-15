import 'package:http/http.dart';

import 'src/web_service_client.dart';
export 'src/http_exception.dart';

class RiveApi extends WebServiceClient {
  final String host = 'http://localhost:3000';
  // inal String host = 'https://stryker.rive.app';
  RiveApi() : super('rive-api') {
    // TODO: might be nice to have a way to add a generic 'not 20X' handler
    this.addStatusCodeHandler(400, handle_400);
    this.addStatusCodeHandler(401, handle_40X);
    this.addStatusCodeHandler(403, handle_40X);
    this.addStatusCodeHandler(500, handle_500);
  }
}

String describeError(Response response) {
  return '[${response.statusCode}] ${response.request.url}: ${response.body.toString()}';
}

void handle_400(Response response) {
  throw BadRequestException('${describeError(response)}');
}

void handle_40X(Response response) {
  throw UnauthorisedException('${describeError(response)}');
}

void handle_500(Response response) {
  throw ServerErrorException('${describeError(response)}');
}

// Taking inspiration here
// https://medium.com/flutter-community/handling-network-calls-like-a-pro-in-flutter-31bd30c86be1
class AppException implements Exception {
  final _message;
  final _prefix;

  AppException([this._message, this._prefix]);

  String toString() {
    return "$_prefix$_message";
  }
}

class BadRequestException extends AppException {
  BadRequestException([message]) : super(message, 'Invalid Request: ');
}

class UnauthorisedException extends AppException {
  UnauthorisedException([message]) : super(message, 'Unauthorised: ');
}

class ServerErrorException extends AppException {
  ServerErrorException([String message]) : super(message, 'Server Error: ');
}
