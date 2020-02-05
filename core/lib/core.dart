import 'dart:async';

import 'package:meta/meta.dart';

import 'coop/change.dart';
import 'coop/connect_result.dart';
import 'coop/coop_client.dart';
import 'coop/local_settings.dart';
import 'core_property_changes.dart';
export 'package:fractional/fractional.dart';
export 'src/list_equality.dart';

int localId = 0;

typedef PropertyChanger = void Function<T>(
    Core object, int propertyKey, T from, T to);

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
  void changeNonNull([PropertyChanger changer]);
}

class FreshChange {
  final CorePropertyChanges change;
  final bool useFrom;

  const FreshChange(this.change, this.useFrom);
}

abstract class CoreContext implements LocalSettings {
  static const int addKey = 1;
  static const int removeKey = 2;
  static const int dependentsKey = 3;

  final String fileId;
  CoopClient _client;
  // Map<int, Core> get objects => _objects;

  final List<CorePropertyChanges> journal = [];
  CorePropertyChanges _currentChanges;

  /// Find a Core object by id.
  T resolve<T>(int id) {
    var object = _objects[id];
    if (object is T) {
      return object as T;
    }
    return null;
  }

  /// Find Core objects of type [T].
  Iterable<T> objectsOfType<T>() => _objects.values.whereType<T>();

  /// Get all objects
  Iterable<Core<CoreContext>> get objects => _objects.values;

  int _journalIndex = 0;
  bool _isRecording = true;
  final Map<int, Core> _objects = {};
  final Map<ChangeSet, FreshChange> _freshChanges = {};
  final List<ChangeSet> _unsyncedChanges = [];
  CoreContext(this.fileId);

  T add<T extends Core>(T object) {
    if (_isRecording) {
      object.id ??= --localId;
    }
    object.context = this;

    _objects[object.id] = object;
    onAdded(object);
    if (_isRecording) {
      changeProperty(object, addKey, removeKey, object.coreType);
      object.changeNonNull();
    }
    return object;
  }

  void onAdded(covariant Core object);
  void onRemoved(covariant Core object);

  bool captureJournalEntry() {
    if (_currentChanges == null) {
      return false;
    }
    completeJournalOperation();

    // nuke remainder of journal, in case we weren't at the end
    journal.removeRange(_journalIndex, journal.length);

    // add the new changes to the journal
    journal.add(_currentChanges);

    // schedule those changes to be sent to other clients (and server for
    // saving)
    _coopMakeChangeSet(_currentChanges, useFrom: false);
    _journalIndex = journal.length;
    _currentChanges = null;
    return true;
  }

  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    if (!_isRecording) {
      return;
    }
    _currentChanges ??= CorePropertyChanges();
    _currentChanges.change(object, propertyKey, from, to);
  }

  Future<ConnectResult> connect(String host, String path) async {
    _client = CoopClient(host, path, fileId: fileId, localSettings: this)
      ..changesAccepted = _changesAccepted
      ..changesRejected = _changesRejected
      ..changeObjectId = _changeObjectId
      ..makeChange = _makeChange
      ..wipe = _wipe
      ..sendOfflineChanges = _sendOfflineChanges;

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

  void _applyJournalEntry(CorePropertyChanges changes, {bool isUndo}) {
    changes.entries.forEach((objectId, objectChanges) {
      bool regenerated = false;
      var object = _objects[objectId];
      if (object == null) {
        var hydrateKey = isUndo ? removeKey : addKey;
        // The object may have been previously deleted, if so this change set
        // would have had an add key.
        entryLoop:
        for (final entry in objectChanges.entries) {
          if (entry.key == hydrateKey) {
            object = makeCoreInstance(entry.value.to as int);
            regenerated = true;
            break entryLoop;
          }
        }
      }
      if (object != null) {
        objectChanges.forEach((propertyKey, change) {
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

        // var changes = CorePropertyChanges();
        // changes.change(object, addKey, removeKey, object.coreType);
        // object.changeNonNull(changes.change);
        // Now need to add it to coop
      }
    });

    _coopMakeChangeSet(changes, useFrom: isUndo);
    completeJournalOperation();
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

  /// Method called when a journal entry is created or applied via an undo/redo.
  @protected
  void completeJournalOperation();

  void remove<T extends Core>(T object) {
    _objects.remove(object.id);
    if (_isRecording) {
      bool wasJustAdded = false;
      if (_currentChanges != null) {
        var objectChanges = _currentChanges.entries[object.id];
        if (objectChanges != null) {
          // When the add key is present in the changes, it means the object was
          // just created in this same operation, so we can prune it from the
          // changes.
          if (objectChanges[addKey] != null) {
            _currentChanges.entries.remove(object.id);
            wasJustAdded = true;
          }
        }
      }
      if (!wasJustAdded) {
        changeProperty(object, removeKey, addKey, object.coreType);
        // TODO: Is there a way we can do this and not network change these? We
        // do this to re-hydrate the object by storing the changes in the
        // undo/redo stack.
        object.changeNonNull();
      }
    }
    onRemoved(object);
  }

  void setObjectProperty(Core object, int propertyKey, Object value);

  @mustCallSuper
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

    // TODO: remove changes from unsynced list, serialize that and save it into
    // an unsynced_change.data file
    _unsyncedChanges.remove(changes);
    // save...
  }

  void _wipe() {
    _objects.clear();
    _journalIndex = 0;
    journal.clear();
    _freshChanges.clear();
    _unsyncedChanges.clear();
  }

  void _sendOfflineChanges() {
    // TODO: load unsynced changes from data file
    // loop through them and _client.queueChanges(sendChanges);
    var unsentChanges = <ChangeSet>[]; // <-- loaded from file
    for (final change in unsentChanges) {
      _client.sendOfflineChange(change);
    }
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
    completeJournalOperation();
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

    for (final changes in journal) {
      changes.changeId(from, to);
    }
    return true;
  }

  void _changesRejected(ChangeSet changes) {
    // TODO: remove the rejected change from unsycned list, and save the local
    // file
    _unsyncedChanges.remove(changes);

    // Re-apply the original value if the changed value matches the current one.
    var fresh = _freshChanges[changes];
    fresh.change.entries.forEach((objectId, changes) {
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

  void _coopMakeChangeSet(CorePropertyChanges changes, {bool useFrom}) {
    if (_client == null) {
      return;
    }
    // Client should only be null during some testing.
    var sendChanges = _client.makeChangeSet();
    changes.entries.forEach((objectId, changes) {
      var objectChanges = ObjectChanges()
        ..objectId = objectId
        ..changes = [];

      var hydrateKey = useFrom ? removeKey : addKey;
      var dehydrateKey = useFrom ? addKey : removeKey;
      changes.forEach((key, entry) {
        if (key == hydrateKey) {
          //changeProperty(object, addKey, removeKey, object.coreType);
          //changeProperty(object, removeKey, addKey, object.coreType);
          print("GOT HYDRATION! $objectId ${entry.from} ${entry.to}");
          var change = makeCoopChange(addKey, entry.to);
          if (change != null) {
            objectChanges.changes.add(change);
          }
        } else if (key == dehydrateKey) {
          print("DEHYDRATE THIS THING.");
          var change = makeCoopChange(removeKey, objectId);
          if (change != null) {
            objectChanges.changes.add(change);
          }
        } else {
          var change = makeCoopChange(key, useFrom ? entry.from : entry.to);
          if (change != null) {
            objectChanges.changes.add(change);
          }
        }
      });

      sendChanges.objects.add(objectChanges);
    });
    _freshChanges[sendChanges] = FreshChange(changes, useFrom);
    _client.queueChanges(sendChanges);
    // TODO: add sendChanges to a list, serialize that and save it into an
    // unsynced_change.data file
    _unsyncedChanges.add(sendChanges);
    // TODO: debounce/isolate/append(_unsyncedChanges);
  }
}
