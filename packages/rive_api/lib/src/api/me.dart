/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';

final _log = Logger('Rive API Me');

class MeApi {
  MeApi() : api = RiveApi();
  final RiveApi api;

  Future<Me> get whoami async {
    final res = await api.getFromPath('/api/me');
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Check that the user's signed in
      if (!_isSignedIn(data)) {
        throw HttpException('User is not signed in');
      }
      return Me.fromData(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting whoami api response: $e');
      rethrow;
    }
  }

  /// Checks to see if the user's signed in
  bool _isSignedIn(Map<String, dynamic> data) => data['signedIn'];
}
