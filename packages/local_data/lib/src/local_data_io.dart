import 'dart:io';
import 'dart:typed_data';

import '../local_data.dart';
import 'data_directory.dart';

class LocalDataIO extends LocalData {
  Directory _dataDirectory;
  final LocalDataIOPlatform platform;
  LocalDataIO(this.platform, String context) : super(context);

  @override
  Future<bool> initialize() async {
    var dir = Directory('${platform.path}/$context');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dataDirectory = dir;
    return true;
  }

  @override
  Future<Uint8List> load(String name) async {
    assert(_dataDirectory != null);
    var file = File('${_dataDirectory.path}/$name');
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<bool> save(String name, Uint8List bytes) async {
    var file = File('${_dataDirectory.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return true;
  }
}

LocalData makeLocalData(LocalDataPlatform platform, String context) =>
    LocalDataIO(platform, context);

class LocalDataIOPlatform extends LocalDataPlatform {
  String _path;
  String get path => _path;

  Future<bool> initialize() async {
    var dir = await dataDirectory('');
    _path = dir?.path;
    return _path != null;
  }
}

LocalDataPlatform makeLocalDataPlatform() => LocalDataIOPlatform();
