import 'dart:async';

import 'package:rive_api/src/view_model/me.dart';
import 'package:rive_api/src/api/me.dart';
import 'package:rxdart/rxdart.dart';

/// Why do we pass in api here when the manager
/// can easily just access the singleton itself?
/// It lets us pass in a mock api for testing!
class MeManager {
  MeManager({StreamController<MeVM> controller, MeApi api})
      : _api = api ?? MeApi(),
        _meController = controller ?? BehaviorSubject<MeVM>() {
    // Fetch user details when stream is first listened to
    _meController.onListen = _fetchMe;
  }
  final MeApi _api;

  /*
   * Outbound
   */

  final BehaviorSubject<MeVM> _meController;
  Stream<MeVM> get me => _meController.stream;

  /*
   * Inbound
   */

  /// Reloads the logged in user
  void reload() => _fetchMe();

  void dispose() => _meController.close();

  /*
   * API interface
   */

  void _fetchMe() async =>
      _api.whoami.then((me) => _meController.add(MeVM.fromModel(me)));
}
