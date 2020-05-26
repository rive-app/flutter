/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';

final _log = Logger('Rive API Me');

class MeApi {
  MeApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<MeDM> get whoami async {
    final res = await api.getFromPath('/api/me');
    try {
      final data = json.decode(res.body) as Map<String, Object>;
      final extra = data['extra'];
      if (_canLinkAccounts(extra)) {
        return MeDM.fromSocialLink(extra);
      }

      // Check that the user's signed in
      if (!_isSignedIn(data)) {
        return null;
      }
      return MeDM.fromData(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting whoami api response: $e');
      rethrow;
    }
  }

  /// Checks to see if the user's signed in
  bool _isSignedIn(Map<String, Object> data) => data['signedIn'];

  bool _canLinkAccounts(Object extra) {
    if (extra is Map<String, Object>) {
      return extra.containsKey('nm');
    }
    return false;
  }

  Future<bool> signout() async {
    var response = await api.getFromPath('/signout');
    if (response.statusCode == 200 || response.statusCode == 302) {
      await api.clearCookies();
      return true;
    }
    return false;
  }

  Future<MeDM> linkAccounts() async {
    try {
      final res = await api.getFromPath('/api/linkAccount');
      final data = json.decode(res.body) as Map<String, Object>;
      if (!_isSignedIn(data)) {
        return null;
      }
      return MeDM.fromData(data);
    } on FormatException catch (e) {
      _log.severe("Error from '/api/linkAccounts': $e");
      rethrow;
    }
  }

  Future<void> stopLink() async {
    try {
      await api.getFromPath('/api/cancelLink');
    } on FormatException catch (e) {
      _log.severe("Error from '/api/linkAccounts': $e");
      rethrow;
    }
  }
}
