import 'dart:async';

import 'package:rive_api/src/model/volume.dart';
import 'package:rive_api/src/api/volume.dart';
import 'package:rxdart/rxdart.dart';

class VolumeManager {
  VolumeManager([VolumeApi api]) : _api = api ?? VolumeApi() {
    _volumesController.onListen = _fetchVolumes;
  }
  final VolumeApi _api;

  /*
   * Outbound streams
   */

  final _volumesController = BehaviorSubject<Iterable<Volume>>();
  Stream<Iterable<Volume>> get volumes => _volumesController.stream;

  void dispose() => _volumesController.close();

  /*
   * API interface
   */

  void _fetchVolumes() async => _volumesController.add(await _api.volumes);
}
