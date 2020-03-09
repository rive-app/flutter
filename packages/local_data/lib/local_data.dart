import 'dart:typed_data';

import 'src/local_data_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'src/local_data_io.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'src/local_data_web.dart';

abstract class LocalData {
  final String context;
  LocalData(this.context);
  Future<bool> initialize();
  Future<bool> save(String name, Uint8List bytes);
  Future<Uint8List> load(String name);

  factory LocalData.make(String context) {
    return makeLocalData(context);
  }
}
