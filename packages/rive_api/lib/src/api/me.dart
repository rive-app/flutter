/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('Rive API Me');

class MeApi {
  MeApi() : api = RiveApi();
  final RiveApi api;

  Future<Me> whoami() async {
    final res = await api.getFromPath('/api/me');
    print(res.statusCode);
    print(res.body);
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Check that the user's signed in
      if (!_isSignedIn(data)) {
        throw HttpException('User is not signed in');
      }
      return Me.fromData(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting me api response: $e');
      throw e;
    }
  }

  /// Checks to see if the user's signed in
  bool _isSignedIn(Map<String, dynamic> data) => data['signedIn'];
}
