import 'dart:convert';

import 'package:http/http.dart';

import 'src/web_service_client.dart';
export 'src/http_exception.dart';

class RiveApi extends WebServiceClient {
  // final String host = 'http://localhost:3000';
  final String host = 'https://stryker.rive.app';
  RiveApi() : super('rive-api') {
    // TODO: might be nice to have a way to add a generic 'not 20X' handler
    this.addStatusCodeHandler(400, handle_exception);
    this.addStatusCodeHandler(401, handle_exception);
    this.addStatusCodeHandler(403, handle_exception);
    this.addStatusCodeHandler(500, handle_exception);
  }
}

void handle_exception(Response response) {
  throw ApiException(response);
}

// Taking inspiration here
// https://medium.com/flutter-community/handling-network-calls-like-a-pro-in-flutter-31bd30c86be1
class ApiException implements Exception {
  final Response _response;
  APIError error;

  ApiException(this._response){
    try{
      Map<String, dynamic> data = json.decode(_response.body);
      error = APIError(message:data['error']['message'], code:data['error']['code']);
      } catch (_) {
        // if creating the error goes wrong, just stick it all into the error message
        error = APIError(message: _response.body.toString());
      }
  }

  String toString() {
    return '[${_response.statusCode}] ${_response.request.url}: ${_response.body.toString()}';
  }

  String displayError() {
    return _response.body.toString();
  }
}

class APIError {
  final String message;
  final String code;

  APIError({this.message, this.code});
}