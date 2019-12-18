class ChangeEntry {
  final Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

// TODO:
// - implement undo/redo
// - implement journal tracker (index based)
// - catches up to perform network sync of changes
// journal[change_index][object_id][property] = {from, to}

abstract class CoreContext {
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
          setObjectProperty(object, propertyKey, change.from);
        });
      }
    });
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
    _journalIndex = index+1;
    var changes = journal[index];
    changes.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((propertyKey, change) {
          setObjectProperty(object, propertyKey, change.to);
        });
      }
    });
    _isRecording = true;
    return true;
  }

  void captureJournalEntry() {
    if (_currentChanges == null) {
      return;
    }
    journal.removeRange(_journalIndex, journal.length);
    journal.add(_currentChanges);
    _journalIndex = journal.length;
    _currentChanges = null;
  }

  T add<T extends Core>(T object) {
    object.id ??= localId--;
    object.context = this;
    _objects[object.id] = object;
    return object;
  }

  void remove<T extends Core>(T object) {
    _objects.remove(object.id);
  }

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }
}

int localId = 0;

class Core {
  int id;
  CoreContext context;
}
