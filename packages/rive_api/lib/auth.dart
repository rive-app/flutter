import 'dart:convert';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_utils/window_utils.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/models/user.dart';

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

  Future<bool> login(String username, String password) async {
    var response = await api.post(api.host + '/signin',
        body: jsonEncode(
          <String, String>{
            'username': username,
            'password': password,
          },
        ));

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> registerGoogle() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'google');

  Future<bool> registerTwitter() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'twitter');

  Future<bool> registerFacebook() =>
      _oAuth(action: _RiveAuthActions.register, provider: 'facebook');

  /// Initiate an OAuth login session with Facebook.
  Future<bool> loginFacebook() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'facebook');

  /// Initiate an OAuth login session with Twitter.
  Future<bool> loginTwitter() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'twitter');

  /// Initiate an OAuth login session with Google.
  Future<bool> loginGoogle() =>
      _oAuth(action: _RiveAuthActions.signin, provider: 'google');

  /// Initiate an OAUth session for the given [action] with one of the
  /// supported [provider]s.
  Future<bool> _oAuth(
      {@required _RiveAuthActions action, @required String provider}) async {
    assert(!kIsWeb, 'Shouldn\'t be authenticating from Flutter Web.');
    var offset = await WindowUtils.getWindowOffset();
    var size = await WindowUtils.getWindowSize();

    var url = api.host + '/desktop/${action.name}/$provider';

    var windowSize = const Size(580, 600);
    String spectre = await WindowUtils.openWebView(
      'auth',
      url,
      size: windowSize,
      offset: Offset(
        offset.dx + size.width / 2 - windowSize.width / 2,
        offset.dy + size.height / 2 - windowSize.height / 2,
      ),
      jsMessage: 'jsHandler',
    );
    if (spectre != null) {
      api.setCookie('spectre', spectre);
      await WindowUtils.closeWebView('auth');
      await api.persist();
    }
    return spectre?.isNotEmpty ?? false;
  }

  Future<RiveUser> whoami() async {
    var response = await api.get(api.host + '/api/me');

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
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

  Future<bool> register(String username, String email, String password) async {
    final body = jsonEncode(
      <String, String>{
        'username': username,
        'password': password,
        'email': email,
      },
    );
    var response = await api.post(api.host + '/register', body: body);

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }
}
