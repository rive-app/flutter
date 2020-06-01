import 'dart:convert';

import 'package:http/http.dart';
import 'package:rive_api/http.dart';
import 'package:utilities/deserialize.dart';

void handleException(Response response) => throw ApiException(response);

class APIError {
  final String message;
  final String code;
  APIError({this.message, this.code});
}

// Taking inspiration here
// https://medium.com/flutter-community/handling-network-calls-like-a-pro-in-flutter-31bd30c86be1
class ApiException implements Exception {
  final Response _res;

  APIError error;
  ApiException(Response response) : _res = response {
    try {
      final errorData =
          json.decodeMap(_res.body).getMap<String, dynamic>('error');

      error = APIError(
        message: errorData.getString('message'),
        code: errorData.getString('code'),
      );
    }
    // We want to catch all here...
    // ignore: avoid_catches_without_on_clauses
    catch (_) {
      // if creating the error goes wrong, just stick it all into the error
      // message
      error = APIError(message: _res.body.toString());
    }
  }

  Response get response => _res;

  String displayError() => _res.body.toString();

  @override
  String toString() =>
      '[${_res.statusCode}] ${_res.request.url}: ${_res.body.toString()}';
}

/// Now uses a singleton
class RiveApi extends WebServiceClient {
  static final RiveApi _instance = RiveApi._();
  final String host = 'https://stryker.rive.app';
  factory RiveApi() => _instance;

  // final host = 'http://localhost:3000';
  RiveApi._() : super('rive-api') {
    addAcceptableStatusCodes([StatusCodeClass.success], handleException);
  }

  Future<Response> getFromPath(String path) {
    return this.get(host + path);
  }
}
