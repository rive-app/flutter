import 'dart:async';

import 'package:meta/meta.dart';

import 'coop/change.dart';
import 'coop/connect_result.dart';
import 'coop/coop_client.dart';
import 'coop/local_settings.dart';
export 'package:fractional/fractional.dart';

int localId = 0;

// TODO:
// - catches up to perform network sync of changes
// journal[change_index][object_id][property] = {from, to}

class ChangeEntry {
  Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

abstract class Core<T extends CoreContext> {
  int id;
  T context;
  int get coreType;

  @protected
  void changeNonNull();
}

class FreshChange {
  final Map<int, Map<int, ChangeEntry>> change;
  final bool useFrom;

  const FreshChange(this.change, this.useFrom);
}

abstract class CoreContext implements LocalSettings {
  static const int addKey = 1;
  static const int removeKey = 2;

  final String fileId;
  CoopClient _client;
  Map<int, Core> get objects => _objects;

  final List<Map<int, Map<int, ChangeEntry>>> journal =
      <Map<int, Map<int, ChangeEntry>>>[];
  Map<int, Map<int, ChangeEntry>> _currentChanges;

  int _journalIndex = 0;
  bool _isRecording = true;
  final Map<int, Core> _objects = {};
  final Map<ChangeSet, FreshChange> _freshChanges = {};
  CoreContext(this.fileId);

  T add<T extends Core>(T object) {
    if (_isRecording) {
      object.id ??= --localId;
    }
    object.context = this;

    _objects[object.id] = object;
    print("ADDING ${object.id} $object $_objects");
    onAdded(object);
    if (_isRecording) {
      changeProperty(object, addKey, removeKey, object.coreType);
      object.changeNonNull();
    }
    return object;
  }

  void onAdded(Core object);
  void onRemoved(Core object);

  bool captureJournalEntry() {
    if (_currentChanges == null) {
      return false;
    }
    journal.removeRange(_journalIndex, journal.length);
    journal.add(_currentChanges);
    _coopMakeChangeSet(_currentChanges, useFrom: false);
    _journalIndex = journal.length;
    _currentChanges = null;
    return true;
  }

  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    if (!_isRecording) {
      return;
    }
    _currentChanges ??= <int, Map<int, ChangeEntry>>{};
    var changes = _currentChanges[object.id];
    if (changes == null) {
      _currentChanges[object.id] = changes = <int, ChangeEntry>{};
    }
    var change = changes[propertyKey];
    if (change == null) {
      changes[propertyKey] = change = ChangeEntry(from, to);
    } else {
      change.to = to;
    }
  }

  Future<ConnectResult> connect(String url) async {
    _client = CoopClient(url, fileId: fileId, localSettings: this)
      ..changesAccepted = _changesAccepted
      ..changesRejected = _changesRejected
      ..changeObjectId = _changeObjectId
      ..makeChange = _makeChange;

    return _client.connect();
  }

  Future<bool> disconnect() async {
    var disconnectResult = await _client.disconnect();
    _client = null;
    return disconnectResult;
  }

  Object getObjectProperty(Core object, int propertyKey);

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }

  @protected
  Change makeCoopChange(int propertyKey, Object value);

  @protected
  Core makeCoreInstance(int typeKey);

  @protected
  void applyCoopChanges(ObjectChanges objectChanges);

  void _applyJournalEntry(Map<int, Map<int, ChangeEntry>> entry,
      {bool isUndo}) {
    entry.forEach((objectId, changes) {
      bool regenerated = false;
      var object = _objects[objectId];
      if (object == null) {
        var hydrateKey = isUndo ? removeKey : addKey;
        // The object may have been previously deleted, if so this change set
        // would had an add key.
        entryLoop:
        for (final entry in changes.entries) {
          if (entry.key == hydrateKey) {
            object = makeCoreInstance(entry.value.to as int);
            regenerated = true;
            break entryLoop;
          }
        }
      }
      if (object != null) {
        changes.forEach((propertyKey, change) {
          if (propertyKey == addKey) {
            if (isUndo) {
              // Had an add key, this is undo, remove it.
              remove(object);
            }
          } else if (propertyKey == removeKey) {
            if (!isUndo) {
              // Had an remove key, this is redo, remove it.
              remove(object);
            }
          } else {
            // Need to re-write history (grab current value as the change.from).
            // We do this to patch-up history items that change when the server
            // sends changes from other clients (or previous changes get
            // rejected).
            if (isUndo) {
              change.to = getObjectProperty(object, propertyKey);
              setObjectProperty(object, propertyKey, change.from);
            } else {
              change.from = getObjectProperty(object, propertyKey);
              setObjectProperty(object, propertyKey, change.to);
            }
          }
        });
      }
      if (regenerated) {
        object.id = objectId;
        object.context = this;
        _objects[object.id] = object;
        onAdded(object);
      }
    });

    _coopMakeChangeSet(entry, useFrom: isUndo);
  }

  bool redo() {
    int index = _journalIndex;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index + 1;
    _applyJournalEntry(journal[index], isUndo: false);
    _isRecording = true;
    return true;
  }

  void remove<T extends Core>(T object) {
    _objects.remove(object.id);
    onRemoved(object);
    if (!_isRecording) {
      return;
    }
    bool wasJustAdded = false;
    if (_currentChanges != null) {
      var objectChanges = _currentChanges[object.id];
      if (objectChanges != null) {
        // When the add key is present in the changes, it means the object was
        // just created in this same operation, so we can prune it from the
        // changes.
        if (objectChanges[addKey] != null) {
          _currentChanges.remove(object.id);
          wasJustAdded = true;
        }
      }
    }
    if (!wasJustAdded) {
      changeProperty(object, removeKey, addKey, object.coreType);
      // TODO: Is there a way we can do this and not network change these? We do
      // this to re-hydrate the object by storing the changes in the undo/redo
      // stack.
      object.changeNonNull();
    }
  }

  void setObjectProperty(Core object, int propertyKey, Object value);

  bool undo() {
    int index = _journalIndex - 1;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index;
    _applyJournalEntry(journal[index], isUndo: true);
    _isRecording = true;
    return true;
  }

  void _changesAccepted(ChangeSet changes) {
    print("ACCEPTING ${changes.id}.");
    _freshChanges.remove(changes);
  }

  void _makeChange(ObjectChanges change) {
    var wasRecording = _isRecording;
    _isRecording = false;
    // print("GOT CHANGE ${change.objectId} ${change.op} ${change.value}");
    // var object = _objects[change.objectId];
    applyCoopChanges(change);
    // switch(change.op) {
    //   case addKey:
    //     break;
    //   case removeKey:
    //     break;
    //   default:
    //     setObjectProperty(object, change.op, change)
    //     break;
    // }
    _isRecording = wasRecording;
  }

  bool _changeObjectId(int from, int to) {
    var object = _objects[from];
    if (object == null) {
      return false;
    }
    // Remove old mapping
    _objects.remove(from);

    // Add new mapping
    object.id = to;
    _objects[to] = object;

    // change journal ids to new one
    // journal[change_index][object_id][property]
    for (final entry in journal) {
      var objectChanges = entry[from];
      // Remap to new id
      if (objectChanges != null) {
        entry.remove(from);
        entry[to] = objectChanges;
      }
    }
    return true;
  }

  void _changesRejected(ChangeSet changes) {
    // Re-apply the original value if the changed value matches the current one.
    var fresh = _freshChanges[changes];
    fresh.change.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((key, entry) {
          // value is still what we had tried to change it too (nothing else has
          // changed it since).
          if ((fresh.useFrom ? entry.from : entry.to) ==
              getObjectProperty(object, key)) {
            // If so, we can reset it to the original value since this change
            // got rejected.
            setObjectProperty(
                object, key, fresh.useFrom ? entry.to : entry.from);
          }
        });
      }
    });
  }

  void _coopMakeChangeSet(Map<int, Map<int, ChangeEntry>> changes,
      {bool useFrom}) {
    if (_client == null) {
      return;
    }
    // Client should only be null during some testing.
    var sendChanges = _client.makeChangeSet();
    changes.forEach((objectId, changes) {
      var objectChanges = ObjectChanges()
        ..objectId = objectId
        ..changes = [];

      changes.forEach((key, entry) {
        var change = makeCoopChange(key, useFrom ? entry.from : entry.to);
        if (change != null) {
          objectChanges.changes.add(change);
        }
      });

      sendChanges.changes.add(objectChanges);
    });
    _freshChanges[sendChanges] = FreshChange(changes, useFrom);
    _client.queueChanges(sendChanges);
  }
}
