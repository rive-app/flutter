/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';
import 'package:rive_api/model.dart';

final _log = Logger('Rive API Me');

class MeApi {
  MeApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<MeDM> get whoami async {
    final res = await api.getFromPath('/api/me');
    try {
      final data = json.decodeMap(res.body);
      Map<String, Object> extra = data.getMap('extra');
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
  bool _isSignedIn(Map<String, Object> data) => data.getBool('signedIn');

  bool _canLinkAccounts(Map<String, Object> extra) =>
      extra?.containsKey('nm') ?? false;

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

  /// Gets the error message from the server's cookies.
  /// Server will also clear it right away, so this error can only be used once.
  Future<String> getErrorMessage() async {
    var response = await api.getFromPath('/api/getError');
    if (response.statusCode != 200) {
      _log.severe("Couldn't clear the errors cookie.");
      return '';
    }
    return response.body;
  }

  /// GET /api/profile
  /// Returns the user profile.
  Future<ProfileDM> get profile async {
    final response = await api.get('${api.host}/api/profile');
    if (response.statusCode != 200) {
      var message = 'Could not get user profile ${response.body}';
      log.severe(message);
      return null;
    }
    try {
      final data = json.decode(response.body) as Map<String, Object>;
      return ProfileDM.fromData(data);
    } on FormatException catch (e) {
      log.severe('Error formatting team profile response: $e');
      rethrow;
    }
  }

  // PUT
  Future<bool> updateProfile(Profile profile) async {
    try {
      var response =
          await api.put('${api.host}/api/profile', body: profile.encoded);
      print("Response: ${response.body}, ${response.statusCode}");
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      print("Response: ${response.body}, ${response.statusCode}");
      var message = 'Could not create new team ${response.body}';
      log.severe(message);
      return false;
    }
  }
}
