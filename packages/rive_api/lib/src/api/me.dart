/// API calls for the logged-in user

import 'dart:convert';
import 'dart:typed_data';
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
      _log.severe('Error formatting whoami api response', e);
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

  Future<bool> signoutApi() async {
    var response = await api.post('${api.host}/api/signout');
    if (response.statusCode == 200 || response.statusCode == 302) {
      await api.clearCookies();
      return true;
    }
    return false;
  }

  Future<void> deleteApi(String password) async {
    var response = await api.delete(
      '${api.host}/api/me',
      body: jsonEncode(
        {
          'data': {'password': password}
        },
      ),
    );
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
      _log.severe("Error from '/api/linkAccounts'", e);
      rethrow;
    }
  }

  Future<void> stopLink() async {
    try {
      await api.getFromPath('/api/cancelLink');
    } on FormatException catch (e) {
      _log.severe("Error from '/api/linkAccounts'", e);
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

  /// GET /api/profile
  /// Returns the user profile.
  Future<TokenDM> get token async {
    final response = await api.get('${api.host}/auth/token');
    if (response.statusCode != 200) {
      var message = 'Could not get user profile ${response.body}';
      log.severe(message);
      return null;
    }
    try {
      final data = json.decode(response.body) as Map<String, Object>;
      return TokenDM.fromData(data);
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
      print('Response: ${response.body}, ${response.statusCode}');
      return true;
    } on ApiException catch (apiException) {
      final response = apiException.response;
      var message = 'Could not update profile: ${response.body}';
      print('Response [${response.statusCode}]:\n$message');
      log.severe(message);
      return false;
    }
  }

  /// Marks that the user has performed first run requirements
  Future<void> markFirstRun() async {
    try {
      await api.patch('${api.host}/api/first-run');
    } on ApiException catch (apiException) {
      final res = apiException.response;
      log.severe('Could not mark first run: ${res.statusCode} - ${res.body}');
    }
  }

  Future<String> uploadAvatar(Uint8List bytes) async {
    var response = await api.post('${api.host}/api/avatar', body: bytes);
    final data = json.decodeMap(response.body);
    return data.getString('url');
  }
}
