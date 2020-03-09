import 'dart:async';
import 'dart:collection';

import 'package:core/id.dart';
import 'package:meta/meta.dart';

import 'coop/change.dart';
import 'coop/connect_result.dart';
import 'coop/coop_client.dart';
import 'coop/coop_command.dart';
import 'coop/local_settings.dart';
import 'coop/player.dart';
import 'coop/player_cursor.dart';
import 'core_property_changes.dart';
import 'debounce.dart';

export 'package:fractional/fractional.dart';
export 'package:core/id.dart';

export 'src/list_equality.dart';

class ChangeEntry {
  Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

typedef PropertyChangeCallback = void Function(dynamic from, dynamic to);
typedef BatchAddCallback = void Function();

abstract class Core<T extends CoreContext> {
  Id id;

  T context;
  int get coreType;

  Set<int> get coreTypes => {};

  HashMap<int, Set<PropertyChangeCallback>> _changeListeners;

  @protected
  void changeNonNull();

  /// Generated classes override this to return the value stored in the field
  /// matching the propertyKey.
  K getProperty<K>(int propertyKey) {
    return null;
  }

  /// Register to receive a notification whenever a property with propertyKey
  /// changes on this object.
  bool addListener(int propertyKey, PropertyChangeCallback callback) {
    assert(callback != null, 'no null listener callbacks');
    _changeListeners ??= HashMap<int, Set<PropertyChangeCallback>>();
    var listeners = _changeListeners[propertyKey];
    if (listeners == null) {
      _changeListeners[propertyKey] = listeners = {};
    }
    return listeners.add(callback);
  }

  /// Remove a previously registered notification for when a property with
  /// propertyKey changes on this object.
  bool removeListener(int propertyKey, PropertyChangeCallback callback) {
    assert(callback != null, 'no null listener callbacks');
    if (_changeListeners == null) {
      return false;
    }
    var listeners = _changeListeners[propertyKey];
    if (listeners == null) {
      return false;
    }
    if (listeners.remove(callback)) {
      // Do some memory cleanup.
      if (listeners.isEmpty) {
        _changeListeners.remove(propertyKey);
      }
      if (_changeListeners.isEmpty) {
        _changeListeners = null;
      }
      return true;
    }
    return false;
  }

  @protected
  void onPropertyChanged<K>(int propertyKey, K from, K to) {
    context?.changeProperty(this, propertyKey, from, to);
    if (_changeListeners == null) {
      return;
    }
    // notify listeners too
    var listeners = _changeListeners[propertyKey];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(from, to);
      }
    }
  }
}

abstract class CoreContext implements LocalSettings {
  static const int addKey = 1;
  static const int removeKey = 2;
  static const int dependentsKey = 3;

  final String fileId;
  CoopClient _client;
  int _lastChangeId;
  // _nextObjectId has a defulat value that will be
  // overridden when a client is connected
  Id _nextObjectId = const Id(0, 0);
  // Map<int, Core> get objects => _objects;

  final List<CorePropertyChanges> journal = [];
  CorePropertyChanges _currentChanges;

  int _journalIndex = 0;

  bool _isRecording = true;

  final Map<Id, Core> _objects = {};

  final Map<ChangeSet, FreshChange> _freshChanges = {};
  // final List<ChangeSet> _unsyncedChanges = [];
  CoreContext(this.fileId) : _lastChangeId = CoopCommand.minChangeId;

  /// When this is set, delay calling onAdded for any object added to Core. This
  /// is helpful when applying many changes at once, knowing that further
  /// changes will be made to the added object. This ensures that we can later
  /// call onAdded when we're done making the changes and onAdded can be called
  /// with sane/stable data.
  List<Core<CoreContext>> _delayAdd;

  /// Some components may try to alter the hierarchy (in a self-healing attempt)
  /// during load. In these cases, batchAdd operations cannot be completed until
  /// the file is fully loaded, so we use this set to track and defer those
  /// operations.
  Set<BatchAddCallback> _deferredBatchAdd;

  final Map<int, Player> _players = {};

  Iterable<Player> get players => _players.values;

  T player<T>(int id) => _players[id] as T;

  /// Get all objects
  Iterable<Core<CoreContext>> get objects => _objects.values;
  T add<T extends Core>(T object) {
    if (_isRecording) {
      object.id ??= _nextObjectId;
      _nextObjectId = _nextObjectId.next;
    }
    object.context = this;

    _objects[object.id] = object;
    if (_delayAdd != null) {
      _delayAdd.add(object);
    } else {
      onAddedDirty(object);
      // Does this ever happen anymore? Shouldn't all our object creations get
      // wrapped in a startAdd?
      onAddedClean(object);
    }
    if (_isRecording) {
      changeProperty(object, addKey, removeKey, object.coreType);
      object.changeNonNull();
    }
    return object;
  }

  @protected
  void applyCoopChanges(ObjectChanges objectChanges);

  @protected
  bool isPropertyId(int propertyKey);

  bool captureJournalEntry() {
    if (_currentChanges == null) {
      return false;
    }
    completeChanges();

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

  /// Method called when a journal entry is created or applied via an undo/redo.
  @protected
  void completeChanges();

  Future<ConnectResult> connect(String host, String path) async {
    int clientId = await getIntSetting('clientId');
    _client = CoopClient(host, path,
        fileId: fileId, clientId: clientId, localSettings: this)
      ..changesAccepted = _changesAccepted
      ..changesRejected = _changesRejected
      ..makeChanges = _receiveCoopChanges
      ..wipe = _wipe
      ..gotClientId = (actualClientId) {
        clientId = actualClientId;
        setIntSetting('clientId', clientId);
      }
      ..getOfflineChanges = () async {
        var changes = await getOfflineChanges();

        for (final change in changes) {
          if (change.id > _lastChangeId) {
            _lastChangeId = change.id;
          }
        }
        return changes;
      }
      ..updatePlayers = _updatePlayers
      ..updateCursor = (int clientId, PlayerCursor cursor) {
        _players[clientId]?.cursor = cursor;
      };

    var result = await _client.connect();
    if (result == ConnectResult.connected) {
      int maxId = 0;
      for (final object in _objects.values) {
        if (object.id.client == clientId) {
          if (object.id.object >= maxId) {
            maxId = object.id.object;
          }
        }
      }
      _nextObjectId = Id(clientId, maxId + 1);

      // Load is complete, we can now process any deferred batch add operations.
      if (_deferredBatchAdd != null) {
        var deferred = Set<BatchAddCallback>.from(_deferredBatchAdd);
        _deferredBatchAdd = null;
        deferred.forEach(batchAdd);
      }
    }
    return result;
  }

  Player makeClientSidePlayer(Player serverPlayer, bool isSelf);

  void onPlayerAdded(covariant Player player);
  void onPlayerRemoved(covariant Player player);
  void onPlayersChanged();

  void _updatePlayers(List<Player> players) {
    // As we iterate players to build client side ones, also track their
    // clientIds so we can later remove ones that are no longer connected.
    Set<int> clientIds = {};
    // Track whether our set of players has changed.
    bool changed = false;
    for (final player in players) {
      clientIds.add(player.clientId);
      if (_players.containsKey(player.clientId)) {
        continue;
      }
      var clientPlayer =
          makeClientSidePlayer(player, _client.clientId == player.clientId);
      _players[player.clientId] = clientPlayer;
      onPlayerAdded(clientPlayer);
      changed = true;
    }

    _players.removeWhere((clientId, player) {
      if (clientIds.contains(clientId)) {
        // dont' remove it, player still active
        return false;
      }
      // player gone
      onPlayerRemoved(player);
      changed = true;
      return true;
    });
    if (changed) {
      onPlayersChanged();
    }
  }

  Future<bool> disconnect() async {
    var disconnectResult = await _client.disconnect();
    _client = null;
    return disconnectResult;
  }

  Future<bool> forceReconnect() async {
    return _client.forceReconnect();
  }

  Object getObjectProperty(Core object, int propertyKey);

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }

  @protected
  Change makeCoopChange(int propertyKey, Object value);

  @protected
  Core makeCoreInstance(int typeKey);

  /// Find Core objects of type [T].
  Iterable<T> objectsOfType<T>() => _objects.values.whereType<T>();

  void onAddedDirty(covariant Core object);
  void onAddedClean(covariant Core object);

  void onRemoved(covariant Core object);

  void onWipe();

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
    assert(object != null, 'Attempted to delete a null object');
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

  /// Find a Core object by id.
  T resolve<T>(Id id) {
    var object = _objects[id];
    if (object is T) {
      return object as T;
    }
    return null;
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

  void _applyJournalEntry(CorePropertyChanges changes, {bool isUndo}) {
    Set<Core> regeneratedObjects = {};
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
        regeneratedObjects.add(object);
        object.id = objectId;
        object.context = this;
        _objects[object.id] = object;
        onAddedDirty(object);

        // var changes = CorePropertyChanges();
        // changes.change(object, addKey, removeKey, object.coreType);
        // object.changeNonNull(changes.change);
        // Now need to add it to coop
      }
    });

    _coopMakeChangeSet(changes, useFrom: isUndo);
    completeChanges();
    for (final object in regeneratedObjects) {
      onAddedClean(object);
    }
  }

  @mustCallSuper
  void _changesAccepted(ChangeSet changes) {
    print("ACCEPTING ${changes.id}.");
    _freshChanges.remove(changes);
    abandonChanges(changes);
  }

  @mustCallSuper
  void _changesRejected(ChangeSet changes) {
    abandonChanges(changes);
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
    // Client should only be null during some testing.
    var sendChanges = ChangeSet()
      ..id = _lastChangeId == null ? null : _lastChangeId++
      ..objects = [];
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
    _client?.queueChanges(sendChanges);
    persistChanges(sendChanges);
  }

  void persistChanges(ChangeSet changes);
  void abandonChanges(ChangeSet changes);

  void startAdd() {
    _delayAdd = [];
  }

  void completeAdd() {
    if (_delayAdd == null) {
      return;
    }
    var delayed = _delayAdd.toList(growable: false);
    _delayAdd = null;

    delayed.forEach(onAddedDirty);
    completeChanges();
    delayed.forEach(onAddedClean);
  }

  void _receiveCoopChanges(ChangeSet changes) {
    // We've received changes from Coop. Initialize the delayAdd list so that
    // onAdded doesn't get called as objects are created. We'll manually call it
    // at the end of this method once all the changes have been made.
    print("STARTING ADD");
    startAdd();

    // Track whether recording was on/off, definitely turn it off during these
    // changes.
    var wasRecording = _isRecording;
    _isRecording = false;
    for (final objectChanges in changes.objects) {
      // TODO: (maybe) This would be the moment to strip out in-flight (fresh)
      // changes from this set to avoid the flickering issue.
      applyCoopChanges(objectChanges);
    }
    print("COMPLETING ADD");
    completeAdd();
    // completeAddDirty();
    _isRecording = wasRecording;
    print("COMPLETE CHANGES");
    // completeChanges();
    // completeAddClean();
    print("ALL DONE!");
  }

  /// Add a set of components as a batched operation, cleaning dirt and
  /// completing after all the components have been added and parented.
  void batchAdd(BatchAddCallback addCallback) {
    // Trying to batch add while connecting/loading. We need to defer to when
    // the load is complete.
    if (_nextObjectId == null) {
      _deferredBatchAdd ??= {};
      _deferredBatchAdd.add(addCallback);
      return;
    }
    // When we're doing a batch add, we always want to be recording.
    bool wasRecording = _isRecording;
    _isRecording = true;
    startAdd();

    addCallback();

    completeAdd();

    _isRecording = wasRecording;
  }

  Future<List<ChangeSet>> getOfflineChanges();

  void _wipe() {
    onWipe();
    _objects.clear();
    _journalIndex = 0;
    journal.clear();
    _freshChanges.clear();

    // TODO: rethink this
    // _unsyncedChanges.clear();
  }

  void cursorMoved(double x, double y) =>
      debounce(() => _client?.sendCursor(x, y),
          duration: const Duration(milliseconds: 33));
}

class FreshChange {
  final CorePropertyChanges change;
  final bool useFrom;

  const FreshChange(this.change, this.useFrom);
}
