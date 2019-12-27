import 'dart:async';
import 'dart:typed_data';

import 'coop/change.dart';
import 'coop/connect_result.dart';
import 'coop/coop_client.dart';
import 'coop/local_settings.dart';

class ChangeEntry {
  final Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

// TODO:
// - catches up to perform network sync of changes
// journal[change_index][object_id][property] = {from, to}

abstract class CoreContext implements LocalSettings {
  static const int addKey = 1;
  static const int removeKey = 2;

  final String fileId;
  CoopClient _client;
  CoreContext(this.fileId);

  final Map<int, Core> objects = <int, Core>{};
  final List<Map<int, Map<int, ChangeEntry>>> journal =
      <Map<int, Map<int, ChangeEntry>>>[];

  Map<int, Map<int, ChangeEntry>> _currentChanges;
  int _journalIndex = 0;
  bool _isRecording = true;
  final Map<int, Core> _objects = {};

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

  bool undo() {
    int index = _journalIndex - 1;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index;
    var changes = journal[index];
    changes.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((propertyKey, change) {
          if (propertyKey == 0) {
            // create
          } else if (propertyKey == 1) {
            // delete
          }
          setObjectProperty(object, propertyKey, change.from);
        });
      }
    });
    _coopMakeChangeSet(changes, true);
    _isRecording = true;
    return true;
  }

  void setObjectProperty(Core object, int propertyKey, Object value);

  bool redo() {
    int index = _journalIndex;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index + 1;
    var changes = journal[index];
    changes.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((propertyKey, change) {
          setObjectProperty(object, propertyKey, change.to);
        });
      }
    });
    _coopMakeChangeSet(changes, false);
    _isRecording = true;
    return true;
  }

  void captureJournalEntry() {
    if (_currentChanges == null) {
      return;
    }
    journal.removeRange(_journalIndex, journal.length);
    journal.add(_currentChanges);
    _coopMakeChangeSet(_currentChanges, false);
    _journalIndex = journal.length;
    _currentChanges = null;
  }

  T add<T extends Core>(T object) {
    object.id ??= localId--;
    object.context = this;
    _objects[object.id] = object;
    changeProperty(object, addKey, removeKey, addKey);
    return object;
  }

  void remove<T extends Core>(T object) {
    _objects.remove(object.id);

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
      // TODO: need to serialize and add logic for re-hydrating on undo.
      changeProperty(object, removeKey, addKey, removeKey);
    }
  }

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }

  Future<ConnectResult> connect(String url) async {
    _client = CoopClient(url, fileId: fileId, localSettings: this);
    return _client.connect();
  }

  Future<bool> disconnect() async {
    var disconnectResult = await _client.disconnect();
    _client = null;
    return disconnectResult;
  }

  Change makeCoopChange(int propertyKey, Object value);

  void _coopMakeChangeSet(
      Map<int, Map<int, ChangeEntry>> changes, bool useFrom) {
    if (_client == null) {
      return;
    }
    // Client should only be null during some testing.
    var sendChanges = _client.makeChangeSet();
    changes.forEach((objectId, changes) {
      changes.forEach((key, entry) {
        var change = makeCoopChange(key, useFrom ? entry.from : entry.to);
        if (change != null) {
          change.objectId = objectId;
          sendChanges.changes.add(change);
        }
      });
    });
    _client.queueChanges(sendChanges);
  }
}

int localId = 0;

class Core {
  int id;
  CoreContext context;
}
