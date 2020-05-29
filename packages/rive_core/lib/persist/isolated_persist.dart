// -> editor-only
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:rive_core/persist/persist.dart';

import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/debounce.dart';
import 'package:local_data/local_data.dart';

final _log = Logger('rive_core');

const String _changesDataName = 'changes';

enum _PersistableAction { add, remove, fetch, wipe }

class _PersistableOperation {
  final ChangeSet persistable;
  final _PersistableAction action;
  _PersistableOperation(this.action, this.persistable);
}

class _IsolatedPersistInitArgument {
  final SendPort sendPort;
  final LocalDataPlatform localDataPlatform;
  final String localDataName;

  _IsolatedPersistInitArgument(
      this.sendPort, this.localDataPlatform, this.localDataName);
}

class _IsolatedPersistBackground {
  // On isolate
  ReceivePort _receiveOnIsolate;
  SendPort _sendToMain;
  final LocalData _localData;
  Map<int, ChangeSet> _persistables;

  _IsolatedPersistBackground(_IsolatedPersistInitArgument arg)
      : _localData = LocalData.make(arg.localDataPlatform, arg.localDataName) {
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
          _log.finest("READ ID ${change.id}");
        }
      } on Exception catch (_) {
        _persistables.clear();
        // TODO: let user this happened (data was corrupt)
      }
    }
    _log.finest("GOT ${_persistables.length} PERSISTABLES!");

    _sendToMain = arg.sendPort;
    _receiveOnIsolate = ReceivePort();
    _receiveOnIsolate.listen((dynamic data) {
      assert(data is _PersistableOperation);
      var op = data as _PersistableOperation;
      bool save = true;
      switch (op.action) {
        case _PersistableAction.add:
          _log.finest("ADDING ${op.persistable.id}");
          _persistables[op.persistable.id] = op.persistable;
          break;
        case _PersistableAction.remove:
          var removed = _persistables.remove(op.persistable.id);
          _log.finest("REMOVING ${op.persistable.id} $removed");
          break;
        case _PersistableAction.fetch:
          _log.finest("GOT FETCH FROM API");
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
      persistable.serialize(writer);
    }
    _localData.save(_changesDataName, writer.uint8Buffer);
  }
}

/// Api to interface with a background persister.
class IsolatedPersist implements RivePersist {
  // On main thread
  final ReceivePort _receiveOnMain = ReceivePort();
  SendPort _sendToIsolate;

  final Completer<void> _initCompleter;

  Completer<List<ChangeSet>> _fetchCompleter;

  IsolatedPersist(LocalDataPlatform localDataPlatform, String name)
      : _initCompleter = Completer() {
    _receiveOnMain.listen((dynamic data) {
      if (data is SendPort) {
        _sendToIsolate = data;
        _initCompleter.complete();
      } else if (data is List<ChangeSet>) {
        var completer = _fetchCompleter;
        _fetchCompleter = null;
        completer?.complete(data);
      }
    });
    Isolate.spawn(
        _isolateEntry,
        _IsolatedPersistInitArgument(
            _receiveOnMain.sendPort, localDataPlatform, name));
  }

  @override
  Future<List<ChangeSet>> changes() {
    _fetchCompleter = Completer<List<ChangeSet>>();
    _isolateAction(_PersistableAction.fetch);
    return _fetchCompleter.future;
  }

  /// Let the isolate know we're done with our list of changes.
  @override
  void wipe() {
    _isolateAction(_PersistableAction.wipe);
  }

  void _isolateAction(_PersistableAction action, [ChangeSet data]) =>
      _initCompleter.future.then(
          (_) => _sendToIsolate.send(_PersistableOperation(action, data)));

  @override
  void add(ChangeSet data) => _isolateAction(_PersistableAction.add, data);

  @override
  void remove(ChangeSet data) =>
      _isolateAction(_PersistableAction.remove, data);
}

void _isolateEntry(_IsolatedPersistInitArgument arg) {
  var backgroundProcess = _IsolatedPersistBackground(arg);
}
// <- editor-only