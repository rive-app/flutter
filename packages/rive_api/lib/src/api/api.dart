import 'dart:convert';

import 'package:http/http.dart';
import 'package:rive_api/src/http/http.dart';

class RiveApi extends WebServiceClient {
  // final String host = 'http://localhost:3000';
  final String host = 'https://stryker.rive.app';
  RiveApi() : super('rive-api') {
    this.addAcceptableStatusCodes([StatusCodeClass.success], handleException);
  }
}

void handleException(Response response) => throw ApiException(response);

// Taking inspiration here
// https://medium.com/flutter-community/handling-network-calls-like-a-pro-in-flutter-31bd30c86be1
class ApiException implements Exception {
  ApiException(Response response) : _response = response {
    try {
      final data = json.decode(_response.body) as Map<String, dynamic>;
      error = APIError(
        message: data['error']['message'],
        code: data['error']['code'],
      );
    } catch (_) {
      // if creating the error goes wrong, just stick it all into the error message
      error = APIError(message: _response.body.toString());
    }
  }

  final Response _response;
  APIError error;

  String toString() =>
      '[${_response.statusCode}] ${_response.request.url}: ${_response.body.toString()}';

  String displayError() => _response.body.toString();
}

class APIError {
  APIError({this.message, this.code});
  final String message;
  final String code;
}
