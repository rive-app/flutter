import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';

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

  void loadMe() async {
    var currentMe = _plumber.peek<Me>();

    var meMessage = Me.fromDM(await _meApi.whoami);

    // TODO: try to reconnect.

    // Skip duplicates.
    if (currentMe != meMessage) {
      _plumber.message<Me>(meMessage);
    }
  }

  /** TODO: reconnecting logic: needs RiveState stream.
     
    Future<RiveUser> updateUser() async {
      UserManager().loadMe();
      var auth = RiveAuth(api);
      // TODO: can probably move nav control into streams
      // and ditch everything below this.
      var me = await auth.whoami();

      print("whoami ready: ${me != null}");

      if (me != null) {
        _user.value = me;
        _state.value = RiveState.editor;

        // Track the currently logged in user. Any error report will include the
        // currently logged in user for context.
        ErrorLogger.instance.user = ErrorLogUser(
          id: me.ownerId.toString(),
          username: me.username,
        );

        await Settings.setString(
            Preferences.spectreToken, api.cookies['spectre']);

        selectTab(systemTab);
        return me;
      } else {
        _state.value = RiveState.login;
      }
      return null;
    }

    Timer _reconnectTimer;

    int _reconnectAttempt = 0;

    /// Retry getting the current user with backoff.
    Future<void> _updateUserWithRetry() async {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      try {
        // await updateUser();
      } on HttpException {
        _state.value = RiveState.disconnected;
      }
      if (_state.value != RiveState.disconnected) {
        _reconnectAttempt = 0;
        return;
      }

      if (_reconnectAttempt < 1) {
        _reconnectAttempt = 1;
      }
      _reconnectAttempt *= 2;
      var duration = Duration(milliseconds: min(10000, _reconnectAttempt * 500));
      print('Will retry connection in $duration.');
      _reconnectTimer = Timer(
          Duration(milliseconds: _reconnectAttempt * 500), _updateUserWithRetry);
    }
   */

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
