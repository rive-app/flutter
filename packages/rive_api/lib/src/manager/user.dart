import 'dart:async';
import 'dart:math';

import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/http.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class UserManager with Subscriptions {
  static final UserManager _instance = UserManager._();
  factory UserManager() => _instance;

  UserManager._() : _meApi = MeApi();

  UserManager.tester(MeApi meApi) {
    _meApi = meApi;
  }

  MeApi _meApi;
  Plumber get _plumber => Plumber();

  // used for testing atm.
  set meApi(MeApi meApi) => _meApi = meApi;

  Future<bool> linkAccounts(bool shouldLink) async {
    if (shouldLink) {
      var meMessage = Me.fromDM(await _meApi.linkAccounts());
      _plumber.message<Me>(meMessage);
    } else {
      await _meApi.stopLink();
    }
    return true;
  }

  Future<void> loadMe() async {
    return _loadWithRetry();
  }

  Future<void> _me() async {
    var meMessage = Me.fromDM(await _meApi.whoami);
    _plumber.message<Me>(meMessage);
    _refreshCurrentDirectory();
  }

  void updateAvatar(String avatarUrl) {
    var me = _plumber.peek<Me>();
    var newMe = me.copyWith(avatarUrl: avatarUrl);
    _plumber.message<Me>(newMe);
    _refreshCurrentDirectory();
  }

  void _refreshCurrentDirectory() {
    // if we're currently selected, lets just trigger that.
    var currentDirectory = _plumber.peek<CurrentDirectory>();
    var me = _plumber.peek<Me>();
    if (currentDirectory != null &&
        currentDirectory.owner.ownerId == me.ownerId) {
      _plumber.message(CurrentDirectory(
        me,
        currentDirectory.folder,
      ));
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
    // Its important to flush the appstate first
    // as certain states expect resources to have been loaded.
    _plumber.flush<AppState>();
    _plumber.flushAll();
    _plumber.message(AppState.login);
  }

  Future<bool> signout(bool isWeb) async {
    bool signedOut;
    if (isWeb) {
      signedOut = await _meApi.signout();
    } else {
      signedOut = await _meApi.signoutApi();
    }
    if (signedOut) {
      logout();
    }
    return signedOut;
  }

  Future<void> delete(String password) async {
    await _meApi.deleteApi(password);
    logout();
  }

  /// On FlutterWeb: read the error message from the cookies, if present.
  /// On desktop: empty response.
  Future<String> get errorMessage async {
    final errorMessage = await _meApi.getErrorMessage();
    return errorMessage.isEmpty ? null : errorMessage;
  }

  /// Mark that a user has performed first run requirements
  /// Disables the first run flag in the db
  void markFirstRun() => _meApi.markFirstRun();
}
