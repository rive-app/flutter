import 'dart:io';
import 'dart:typed_data';

import '../local_data.dart';
import 'data_directory.dart';

class LocalDataIO extends LocalData {
  Directory _dataDirectory;
  LocalDataIO(String context) : super(context);

  @override
  Future<bool> initialize() async {
    _dataDirectory = await dataDirectory(context);
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

LocalData makeLocalData(String context) => LocalDataIO(context);
