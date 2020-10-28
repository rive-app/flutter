import 'dart:convert';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/user.dart';
import 'package:window_utils/window_utils.dart' as win_utils;
import 'package:utilities/deserialize.dart';

const _authWebViewKey = 'auth';
enum _RiveAuthActions { signin, register }

extension _AuthActionsNames on _RiveAuthActions {
  String get name => {
        _RiveAuthActions.signin: 'signin',
        _RiveAuthActions.register: 'register',
      }[this];
}

class RiveAuth {
  final RiveApi api;
  RiveAuth(this.api);

  Future<AuthResponse> login(String username, String password) async {
    try {
      var response = await api.post(api.host + '/signin',
          body: jsonEncode(
            <String, String>{
              'username': username,
              'password': password,
            },
          ));

      dynamic responseData = json.decode(response.body);
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('username')) {
          dynamic username = responseData['username'];
          if (username is String) {
            return AuthResponse.fromMessage(username);
          }
        }
      }
    } on FormatException catch (err) {
      return AuthResponse.fromError(description: err.message);
    } on ApiException catch (apiException) {
      final response = apiException.response;
      if (response.statusCode == 422) {
        dynamic responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('error')) {
            dynamic error = responseData['error'];
            return AuthResponse.fromError(
                description: error is String ? error : 'Unknown error');
          }
        }
      }
    }

    return AuthResponse.empty();
  }

  Future<AuthResponse> registerGoogle() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'google');

  Future<AuthResponse> registerTwitter() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'twitter');

  Future<AuthResponse> registerFacebook() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'facebook');

  /// Initiate an OAuth login session with Facebook.
  Future<AuthResponse> loginFacebook() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'facebook');

  /// Initiate an OAuth login session with Twitter.
  Future<AuthResponse> loginTwitter() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'twitter');

  /// Initiate an OAuth login session with Google.
  Future<AuthResponse> loginGoogle() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'google');

  /// Initiate an OAUth session for the given [action] with one of the
  /// supported [provider]s.
  Future<AuthResponse> _oAuth(
      {@required _RiveAuthActions action, @required String provider}) async {
    if (kIsWeb) {
      final onlySignin = action == _RiveAuthActions.signin;
      win_utils.openWebView(
        _authWebViewKey,
        '${api.host}/signin/$provider?onlySignin=$onlySignin',
      );
      return AuthResponse.empty();
    }

    var offset = await win_utils.getWindowOffset();
    var size = await win_utils.getWindowSize();

    var windowSize = const Size(800, 600);
    String response = await win_utils.openWebView(
      _authWebViewKey,
      '${api.host}/desktop/${action.name}/$provider',
      size: windowSize,
      offset: Offset(
        offset.dx + size.width / 2 - windowSize.width / 2,
        offset.dy + size.height / 2 - windowSize.height / 2,
      ),
      jsMessage: 'jsHandler',
    );

    if (response == null) {
      await win_utils.closeWebView(_authWebViewKey);
      return AuthResponse.empty();
    }

    Map<String, Object> responseData;

    try {
      dynamic parsed = json.decode(response);
      AuthResponse authResponse;
      if (parsed is Map<String, dynamic>) {
        responseData = parsed;
        var spectre = responseData.getString('spectre');
        if (spectre != null) {
          authResponse = AuthResponse.fromMessage(spectre);
          api.setCookie('spectre', spectre);
          await api.persist();
        } else if (responseData.getString('error') != null) {
          authResponse = AuthResponse.fromError(
              description: responseData.getString('spectre'));
        }
      }
      await win_utils.closeWebView(_authWebViewKey);
      return authResponse ?? AuthResponse.empty();
    } on FormatException catch (err) {
      await win_utils.closeWebView(_authWebViewKey);
      return AuthResponse.fromError(description: err.message);
    }
  }

  Future<RiveUser> whoami() async {
    var response = await api.get(api.host + '/api/me');

    if (response.statusCode == 200) {
      Map<String, Object> data;
      try {
        data = json.decode(response.body) as Map<String, Object>;
      } on FormatException catch (_) {
        return null;
      }
      return RiveUser.fromData(data);
    }
    return null;
  }

  Future<bool> signout() async {
    var response = await api.get(api.host + '/signout');
    if (response.statusCode == 200) {
      await api.clearCookies();
      return true;
    }
    return false;
  }

  Future<bool> forgot(String emailOrUsername) async {
    var response =
        await api.post(api.host + '/signin/forgot?id=$emailOrUsername');
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<AuthResponse> register(
      String username, String email, String password) async {
    final body = jsonEncode(
      <String, String>{
        'username': username,
        'password': password,
        'email': email,
      },
    );
    try {
      var response = await api.post(api.host + '/register', body: body);
      dynamic data = json.decode(response.body);
      Map<String, Object> responseData;
      if (data is Map<String, Object>) {
        responseData = data;
      }

      if (response.statusCode == 200 &&
          responseData.getString('username') != null) {
        return AuthResponse.fromMessage(responseData.getString('username'));
      }
    } on FormatException catch (err) {
      return AuthResponse.fromError(description: err.message);
    } on ApiException catch (apiException) {
      final response = apiException.response;
      dynamic data = json.decode(response.body);
      Map<String, Object> responseData;
      if (data is Map<String, Object>) {
        responseData = data;
      }
      if (response.statusCode == 422) {
        return AuthResponse.fromErrors(responseData);
      }
    }
    return AuthResponse.empty();
  }

  Future<bool> reset(String password, String token) async {
    final body = jsonEncode(
      <String, String>{'password': password},
    );
    try {
      var response =
          await api.post('${api.host}/signin/reset/$token', body: body);
      print('All good? ${response.statusCode}');

      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      if (response.statusCode == 422) {
        return false;
      }
    }
    return false;
  }
}

class AuthResponse {
  String message;
  Map<String, String> errors;
  AuthResponse.empty(); // Empty response.
  AuthResponse.fromMessage(this.message);
  AuthResponse.fromError({String name = 'error', String description})
      : errors = {name: description};
  AuthResponse.fromErrors(Map<String, Object> networkErrors) {
    errors = {};
    networkErrors.forEach((key, value) {
      if (value is String) {
        errors[key] = value;
      }
    });
  }

  bool get isEmpty => message == null && errors == null;
  bool get isError => errors != null && errors.isNotEmpty;
  bool get isMessage => message != null && message.isNotEmpty;

  @override
  String toString() {
    if (isEmpty) return 'empty';
    if (isMessage) return message;
    String errorString = '';
    errors.forEach((key, value) {
      errorString += '$key: $value\n';
    });
    return errorString.trimRight();
  }
}
