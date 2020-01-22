import 'dart:html';
import 'dart:indexed_db' as idb;
import 'dart:typed_data';

import '../local_data.dart';

class LocalDataWeb extends LocalData {
  LocalDataWeb(String context) : super(context);
  idb.Database _database;

  @override
  Future<bool> initialize() async {
    _database =
        await window.indexedDB.open(context, version: 2, onUpgradeNeeded: (e) {
      _database = e.target.result as idb.Database;
      if (!_database.objectStoreNames.contains(context)) {
        _database.createObjectStore(context);
      }
    });
    return true;
  }

  @override
  Future<Uint8List> load(String name) async {
    var store =
        _database.transaction(context, 'readwrite').objectStore(context);
    var obj = await store.getObject(name);
    if (obj is Uint8List) {
      return obj;
    }
    return null;
  }

  @override
  Future<bool> save(String name, Uint8List bytes) async {
    var store =
        _database.transaction(context, 'readwrite').objectStore(context);
    store.put(bytes, name);
    return true;
  }
}

LocalData makeLocalData(String context) => LocalDataWeb(context);
