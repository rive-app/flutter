import 'dart:convert';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_utils/window_utils.dart';

import 'api.dart';
import 'user.dart';

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

    // print('body ${response.body} ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  /// Initiate an OAuth login session with Facebook.
  Future<bool> loginFacebook() => _loginOAuth('facebook');

  /// Initiate an OAuth login session with Twitter.
  Future<bool> loginTwitter() => _loginOAuth('twitter');

  /// Initiate an OAuth login session with Google.
  Future<bool> loginGoogle() => _loginOAuth('google');

  Future<bool> _loginOAuth(String provider) async {
    assert(!kIsWeb, 'Shouldn\'t be authenticating from Flutter Web.');
    var offset = await WindowUtils.getWindowOffset();
    var size = await WindowUtils.getWindowSize();

    var windowSize = const Size(500, 600);
    String spectre = await WindowUtils.openWebView(
      'auth',
      api.host + '/desktop/signin/$provider',
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
    return spectre.isNotEmpty;
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
}
