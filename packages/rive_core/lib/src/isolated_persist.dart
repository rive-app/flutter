import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/debounce.dart';
import 'package:local_data/local_data.dart';

const String _changesDataName = 'changes';

enum _PersistableAction { add, remove, fetch, wipe }

class _PersistableOperation {
  final ChangeSet persistable;
  final _PersistableAction action;
  _PersistableOperation(this.action, this.persistable);
}

class _IsolatedPersistInitArgument {
  final SendPort sendPort;
  final String localDataName;

  _IsolatedPersistInitArgument(this.sendPort, this.localDataName);
}

class _IsolatedPersistBackground {
  // On isolate
  ReceivePort _receiveOnIsolate;
  SendPort _sendToMain;
  final LocalData _localData;
  Map<int, ChangeSet> _persistables;

  _IsolatedPersistBackground(_IsolatedPersistInitArgument arg)
      : _localData = LocalData.make(arg.localDataName) {
    _init(arg);
  }

  Future<void> _init(_IsolatedPersistInitArgument arg) async {
    await _localData.initialize();
    Uint8List value = await _localData.load(_changesDataName);
    _persistables = {};
    if (value != null) {
      var reader = BinaryReader.fromList(value);
      // TODO: find specific exceptions
      try {
        while (!reader.isEOF) {
          var change = ChangeSet()..deserialize(reader);
          _persistables[change.id] = change;
          print("READ ID ${change.id}");
        }
      } on Exception catch (_) {
        _persistables.clear();
        // TODO: let user this happened (data was corrupt)
      }
    }
    print("GOT ${_persistables.length} PERSISTABLES!");

    _sendToMain = arg.sendPort;
    _receiveOnIsolate = ReceivePort();
    _receiveOnIsolate.listen((dynamic data) {
      assert(data is _PersistableOperation);
      var op = data as _PersistableOperation;
      bool save = true;
      switch (op.action) {
        case _PersistableAction.add:
        print("ADDING ${op.persistable.id}");
          _persistables[op.persistable.id] = op.persistable;
          break;
        case _PersistableAction.remove:
        
          var removed = _persistables.remove(op.persistable.id);
          print("REMOVING ${op.persistable.id} $removed");
          break;
        case _PersistableAction.fetch:
          print("GOT FETCH FROM API");
          save = false;
          _sendToMain.send(_persistables.values.toList(growable: false));
          break;
        case _PersistableAction.wipe:
          _persistables.clear();
          break;
      }
      if (save) {
        debounce(_save, duration: const Duration(seconds: 4));
      }
    });
    _sendToMain.send(_receiveOnIsolate.sendPort);
  }

  void _save() {
    var writer = BinaryWriter();
    for (final persistable in _persistables.values) {
      print("PERSIST ID ${persistable.id}");
      persistable.serialize(writer);
    }
    _localData.save(_changesDataName, writer.uint8Buffer);
    print("SAVED ${_persistables.length} PERSISTABLES!");
  }
}

/// Api to interface with a background persister.
class IsolatedPersist {
  // On main thread
  final ReceivePort _receiveOnMain = ReceivePort();
  SendPort _sendToIsolate;

  final Completer<void> _initCompleter;

  Completer<List<ChangeSet>> _fetchCompleter;

  IsolatedPersist(String name) : _initCompleter = Completer() {
    _receiveOnMain.listen((dynamic data) {
      if (data is SendPort) {
        _sendToIsolate = data;
        _initCompleter.complete();
      } else if (data is List<ChangeSet>) {
        _fetchCompleter?.complete(data);
      }
    });
    Isolate.spawn(_isolateEntry,
        _IsolatedPersistInitArgument(_receiveOnMain.sendPort, name));
  }

  Future<List<ChangeSet>> changes() {
    _fetchCompleter = Completer<List<ChangeSet>>();
    _isolateAction(_PersistableAction.fetch);
    return _fetchCompleter.future;
  }

  /// Let the isolate know we're done with our list of changes.
  void wipe() {
    _isolateAction(_PersistableAction.wipe);
  }

  void _isolateAction(_PersistableAction action, [ChangeSet data]) =>
      _initCompleter.future.then(
          (_) => _sendToIsolate.send(_PersistableOperation(action, data)));

  void add(ChangeSet data) => _isolateAction(_PersistableAction.add, data);

  void remove(ChangeSet data) =>
      _isolateAction(_PersistableAction.remove, data);
}

void _isolateEntry(_IsolatedPersistInitArgument arg) {
  var backgroundProcess = _IsolatedPersistBackground(arg);
}
