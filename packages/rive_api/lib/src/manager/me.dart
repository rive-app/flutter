import 'dart:async';

import 'package:rive_api/src/model/me.dart';
import 'package:rive_api/src/api/me.dart';
import 'package:rxdart/rxdart.dart';

/// Why do we pass in api here when the manager
/// can easily just access the singleton itself?
/// It lets us pass in a mock api for testing!
class MeManager {
  MeManager([MeApi api]) : _api = api ?? MeApi() {
    // Fetch user details when stream is first listened to
    _meController.onListen = _fetchMe;
  }
  final MeApi _api;

  /*
   * Outbound streams
   */

  final _meController = BehaviorSubject<Me>();
  Stream<Me> get me => _meController.stream;

  void dispose() => _meController.close();

  /*
   * API interface
   */

  void _fetchMe() async => _meController.add(await _api.whoami);
}
