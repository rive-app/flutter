import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/api/api.dart';

class UserManager with Subscriptions {
  static UserManager _instance = UserManager._();
  factory UserManager() => _instance;

  UserManager._() {
    _meApi = MeApi();
    _plumber = Plumber();
  }

  Me _me;
  MeApi _meApi;
  Plumber _plumber;

  void loadMe() async {
    _me = Me.fromDM(await _meApi.whoami);
    _plumber.message(_me);
  }

  void logout() async {
    // killMe() ?
    Plumber().clear<Me>();
  }
}
