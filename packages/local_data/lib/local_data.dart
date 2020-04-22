import 'dart:typed_data';

import 'src/local_data_io.dart'
    if (dart.library.html) 'src/local_data_web.dart';

abstract class LocalDataPlatform {
  LocalDataPlatform();
  Future<bool> initialize();
  factory LocalDataPlatform.make() => makeLocalDataPlatform();
}

abstract class LocalData {
  final String context;
  LocalData(this.context);
  Future<bool> initialize();
  Future<bool> save(String name, Uint8List bytes);
  Future<Uint8List> load(String name);

  factory LocalData.make(LocalDataPlatform platform, String context) =>
      makeLocalData(platform, context);
}
