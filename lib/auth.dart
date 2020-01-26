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

  Future<bool> loginTwitter() async {
    assert(!kIsWeb, "Shouldn't be authenticating from Flutter Web.");
    print('go ${api.host + '/desktop/signin/twitter'}');
    String spectre = await WindowUtils.openWebView(
        'auth_window', api.host + '/desktop/signin/twitter',
        size: const Size(1024, 1024), jsMessage: 'jsHandler');
    print('GOT A SPECTRE OF $spectre');
    return true;
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
