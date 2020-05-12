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
    var me = Me.fromDM(await _meApi.whoami);

    // Skip duplicates.
    if (currentMe != me) {
      _plumber.message<Me>(me);
    }
  }

  void logout() async {
    // killMe() ?
    _plumber.flush<Me>();
  }

  Future<bool> signout() async {
    final res = await _meApi.signout();
    if (res) {
      logout();
    }
    return res;
  }
}
