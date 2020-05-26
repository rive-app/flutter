import 'dart:async';
import 'dart:math';

import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/http.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class UserManager with Subscriptions {
  static UserManager _instance = UserManager._();
  factory UserManager() => _instance;

  UserManager._() : _meApi = MeApi();

  UserManager.tester(MeApi meApi) {
    _meApi = meApi;
  }

  MeApi _meApi;
  Plumber get _plumber => Plumber();

  // used for testing atm.
  void set meApi(MeApi meApi) => _meApi = meApi;

  Future<bool> linkAccounts(bool shouldLink) async {
    if (shouldLink) {
      var meMessage = Me.fromDM(await _meApi.linkAccounts());
      _plumber.message<Me>(meMessage);
    } else {
      await _meApi.stopLink();
    }
    return true;
  }

  void loadMe() async {
    _loadWithRetry();
  }

  void _me() async {
    var currentMe = _plumber.peek<Me>();

    var meMessage = Me.fromDM(await _meApi.whoami);
    // Skip duplicates.
    if (currentMe != meMessage) {
      _plumber.message<Me>(meMessage);
    }
  }

  Timer _reconnectTimer;
  int _reconnectAttempt = 0;

  Future<void> _loadWithRetry() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      await _me();
    } on HttpException {
      Plumber().message<AppState>(AppState.disconnected);
    }

    if (Plumber().peek<AppState>() != AppState.disconnected) {
      _reconnectAttempt = 0;
      return;
    }

    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
    var duration = Duration(milliseconds: min(10000, _reconnectAttempt * 500));
    _reconnectTimer = Timer(duration, _loadWithRetry);
  }

  void logout() {
    var emptyMe = Me.fromDM(null);
    _plumber.message<Me>(emptyMe);
  }

  Future<bool> signout() async {
    final res = await _meApi.signout();
    if (res) {
      logout();
    }
    return res;
  }
}
