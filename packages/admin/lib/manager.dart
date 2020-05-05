import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/models/user.dart';
import 'package:rxdart/rxdart.dart';

class AdminManager {
  static final AdminManager instance = AdminManager._();

  final api = RiveApi();
  RiveAuth _auth;

  final _user = BehaviorSubject<RiveUser>();
  Stream<RiveUser> get user => _user.stream;

  final _ready = BehaviorSubject<bool>();
  Stream<bool> get ready => _ready.stream;

  AdminManager._() {
    initialize();
  }

  Future<bool> initialize() async {
    var ready = await api.initialize();
    if (ready) {
      _ready.add(ready);
      _auth = RiveAuth(api);
      _updateMe();
      return true;
    }

    return false;
  }

  Future<void> _updateMe() async => _user.add(await _auth.whoami());

  Future<AuthResponse> login(String username, String password) async {
    var response = await _auth.login(username, password);
    if (!response.isError) {
      _updateMe();
    }
    return response;
  }

  Future<bool> signout() async {
    var result = await _auth.signout();
    _updateMe();
    return result;
  }

  Future<bool> impersonate(String username) async {
    var response = await api.get(api.host + '/impersonate/$username');
    if (response.statusCode == 200) {
      _updateMe();
      return true;
    }
    return false;
  }
}
