import 'dart:convert';
import 'package:http/http.dart';
import 'package:rive_api/http.dart';

/// Now uses a singleton
class RiveApi extends WebServiceClient {
  RiveApi._() : super('rive-api') {
    this.addAcceptableStatusCodes([StatusCodeClass.success], handleException);
  }
  static final RiveApi _instance = RiveApi._();
  factory RiveApi() => _instance;

  // final host = 'http://localhost:3000';
  final host = 'https://stryker.rive.app';

  Future<Response> getFromPath(String path) {
    return this.get(host + path);
  }
}

void handleException(Response response) => throw ApiException(response);

// Taking inspiration here
// https://medium.com/flutter-community/handling-network-calls-like-a-pro-in-flutter-31bd30c86be1
class ApiException implements Exception {
  ApiException(Response response) : _res = response {
    try {
      final data = json.decode(_res.body) as Map<String, dynamic>;
      error = APIError(
        message: data['error']['message'],
        code: data['error']['code'],
      );
    } catch (_) {
      // if creating the error goes wrong, just stick it all into the error message
      error = APIError(message: _res.body.toString());
    }
  }

  final Response _res;
  APIError error;

  Response get response => _res;

  @override
  String toString() =>
      '[${_res.statusCode}] ${_res.request.url}: ${_res.body.toString()}';

  String displayError() => _res.body.toString();
}

class APIError {
  APIError({this.message, this.code});
  final String message;
  final String code;
}
