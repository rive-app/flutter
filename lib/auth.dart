import 'dart:convert';

import 'api.dart';
import 'src/deserialize_helper.dart';
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
