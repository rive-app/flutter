import 'dart:async';
import 'dart:typed_data';

import 'package:core/coop/change.dart';
import 'package:core/debounce.dart';
import 'package:local_data/local_data.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/persist/persist.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

final _log = Logger('rive_core');
const String _changesDataName = 'changes';
const debounceDuration = Duration(seconds: 4);

class IsolatedPersist implements RivePersist {
  IsolatedPersist(LocalDataPlatform localDataPlatform, String name)
      : _localData = LocalData.make(localDataPlatform, name) {
    _init();
  }
  final LocalData _localData;
  final _persistables = <int, ChangeSet>{};

  /// Initializes the local data store, readers, and writers
  Future<void> _init() async {
    await _localData.initialize();
    Uint8List value = await _localData.load(_changesDataName);
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
  }

  @override
  Future<List<ChangeSet>> changes() =>
      Future.value(_persistables.values.toList(growable: false));

  @override
  void wipe() {
    _persistables.clear();
    debounce(_save, duration: debounceDuration);
  }

  @override
  void add(ChangeSet data) {
    _persistables[data.id] = data;
    debounce(_save, duration: debounceDuration);
  }

  @override
  void remove(ChangeSet data) {
    _persistables.remove(data.id);
    debounce(_save, duration: debounceDuration);
  }

  void _save() {
    var writer = BinaryWriter();
    for (final persistable in _persistables.values) {
      persistable.serialize(writer);
    }
    _localData.save(_changesDataName, writer.uint8Buffer);
  }
}
