import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:core/field_types/core_field_type.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:utilities/restorer.dart';

import 'package:core/id.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
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
export 'package:utilities/list_equality.dart';

export 'package:core/field_types/core_bool_type.dart';
export 'package:core/field_types/core_double_type.dart';
export 'package:core/field_types/core_fractional_index_type.dart';
export 'package:core/field_types/core_id_type.dart';
export 'package:core/field_types/core_uint_type.dart';
export 'package:core/field_types/core_list_id_type.dart';
export 'package:core/field_types/core_string_type.dart';
export 'package:core/field_types/core_color_type.dart';

final _log = Logger('Core');

class ChangeEntry {
  Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

typedef PropertyChangeCallback = void Function(dynamic from, dynamic to);
typedef BatchAddCallback = void Function();

abstract class Core<T extends CoreContext> {
  Id id;

  /// Managed by CoreContext internally.
  bool _isActive = false;

  /// Returns true when the object is actively registered with the core context.
  bool get isActive => _isActive;

  covariant T context;
  int get coreType;

  Set<int> get coreTypes => {};

  HashMap<int, Set<PropertyChangeCallback>> _changeListeners;

  @protected
  void changeNonNull();

  bool exports(int propertyKey) => true;

  void writeRuntime(
      BinaryWriter writer, HashMap<int, CoreFieldType> propertyToField,
      [HashMap<Id, int> idLookup]) {
    writer.writeVarUint(coreType);
    writeRuntimeProperties(writer, propertyToField, idLookup);
    // Writer Arnold, I mean Termy.
    writer.writeVarUint(0);
  }

  void writeRuntimeProperties(BinaryWriter writer,
      HashMap<int, CoreFieldType> propertyToField, HashMap<Id, int> idLookup);

  /// Generated classes override this to return the value stored in the field
  /// matching the propertyKey.
  K getProperty<K>(int propertyKey) {
    return null;
  }

  /// Generated classes override this to return whether they store this
  /// property.
  bool hasProperty(int propertyKey) {
    return false;
  }

  /// If an object wishes to delegate specific property key event changes to
  /// another one, override this method to return the appropriate core object
  /// for the key. Make sure to consistenly return the same object based on
  /// propertyKey as this will be called multiple times to bind/unbind.
  // ignore: avoid_returning_this
  Core eventDelegateFor(int propertyKey) => this;

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

  @protected
  @mustCallSuper
  void onAnimatedPropertyChanged<K>(
      int propertyKey, bool autoKey, K from, K to) {
    context?.changeAnimatedProperty(this, propertyKey, autoKey);
    if (_changeListeners == null) {
      return;
    }
    var listeners = _changeListeners[propertyKey];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(from, to);
      }
    }
  }

  /// Called when the object is first added to the context, no validation has
  /// occurred yet.
  void onAddedDirty();

  /// Called once the object has been validated and is cleanly added to the
  /// context.
  void onAdded();

  /// Called when objet is removed from the context.
  void onRemoved();

  /// Override this to ascertain whether or not this object is in a valid state.
  /// If an object is in a corrupt state, it will be removed from core prior to
  /// calling onAdded for the object.
  bool validate() => true;
}

/// Helper interface for something that can resolve Core objects.
abstract class ObjectRoot {
  T resolve<T>(Id id);
  void markDependencyOrderDirty(covariant Core rootObject);
  bool markDependenciesDirty(covariant Core rootObject);
  void removeObject<T extends Core>(T object);
  T addObject<T extends Core>(T object);
}

abstract class CoreContext implements LocalSettings, ObjectRoot {
  static const int addKey = 1;
  static const int removeKey = 2;
  static const int dependentsKey = 3;

  /// Key of the root object to check dependencies on (this is an Artboard in
  /// Rive).
  static const int rootDependencyKey = 1;

  CoopClient _client;
  int _lastChangeId;
  // _nextObjectId has a default value that will be
  // overridden when a client is connected
  Id _nextObjectId = const Id(0, 0);
  Id get nextObjectId => _nextObjectId;
  // Map<int, Core> get objects => _objects;

  final List<CorePropertyChanges> journal = [];
  CorePropertyChanges _currentChanges;

  void debugPrintChanges() {
    print('${_currentChanges.entries.length} changes.');
    _currentChanges.entries.forEach((key, value) {
      var object = resolve<Core>(key);
      print('- $object');
      value.forEach((key, value) {
        print('  - property $key: ${value.to}');
      });
    });
  }

  /// Are there any changes in progress that haven't been captured yet?
  bool get hasRecordedChanges => _currentChanges != null;

  /// Are there any changes in progress that need to be synced to coop?
  bool get hasUnsyncedChanges {
    if (_currentChanges == null) {
      return false;
    }
    for (final changes in _currentChanges.entries.values) {
      for (final key in changes.keys) {
        if (isCoopProperty(key)) {
          return true;
        }
      }
    }
    return false;
  }

  int _journalIndex = 0;

  bool _isRecording = true;
  bool get isApplyingJournalEntry => !_isRecording;

  // Track which entries were changing during animation and need to be reset
  // prior to the next animation pass.
  HashMap<Id, Set<int>> _animationChanges;
  bool get isAnimating => _suppressAutoKey == 0 && _animationChanges != null;

  int _suppressAutoKey = 0;

  /// Prevent the animation system from attempting to key any core changes. This
  /// internally manages a stack that must be balanced by calling restoreAutoKey
  /// when done suppressing in the context that you're calling it from. It also
  /// returns an AutoKeySupression subscription which can be canceled.
  Restorer suppressAutoKey() {
    _suppressAutoKey++;
    return RestoreCallback(_restoreAutoKey);
  }

  /// Restores auto key to previous setting, will return true if this result in
  /// auto keying being re-enabled.
  bool _restoreAutoKey() {
    assert(
        _suppressAutoKey > 0,
        'called restoreAutoKey without a matching suppress, '
        'stack is not balanced');
    _suppressAutoKey--;
    return _suppressAutoKey == 0;
  }

  /// Start tracking changes as keyframe values instead of core property values.
  /// Returns true if animation was actived, false if it was already activated,
  /// either way animation mode is guaranteed to be on after this call.
  bool startAnimating() {
    if (_animationChanges == null) {
      _animationChanges = HashMap<Id, Set<int>>();
      return true;
    }
    // we were already animating...
    return false;
  }

  /// Go back to tracking changes as core property changes. Retruns true if
  /// animation mode was disabled, false if it was already disabled.
  bool stopAnimating() {
    if (_animationChanges == null) {
      return false;
    }
    _animationChanges.forEach(_resetAnimatedObjectProperty);
    _animationChanges = null;
    return true;
  }

  void resetAnimation() {
    _animationChanges.forEach(_resetAnimatedObjectProperty);
    _animationChanges.clear();
  }

  void _resetAnimatedObjectProperty(Id objectId, Set<int> propertyKeys) {
    var coreObject = _objects[objectId];
    for (final propertyKey in propertyKeys) {
      resetAnimated(coreObject, propertyKey);
    }
  }

  final HashMap<Id, Core> _objects = HashMap<Id, Core>();

  @protected
  final Map<ChangeSet, FreshChange> freshChanges = {};
  // final List<ChangeSet> _unsyncedChanges = [];
  CoreContext() : _lastChangeId = CoopCommand.minChangeId;

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

  @override
  T addObject<T extends Core>(T object) {
    if (_isRecording) {
      object.id ??= _nextObjectId;
      _nextObjectId = _nextObjectId.next;
    }
    object.context = this;

    _holdObject(object);
    if (_delayAdd != null) {
      _delayAdd.add(object);
    } else {
      onAddedDirty(object);
      // Does this ever happen anymore? Shouldn't all our object creations get
      // wrapped in a batchAdd?
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

  /// Capture the latest set of changes as a journal entry and sync them to
  /// coop. Set [record] to false if you don't want this change to be undone.
  bool captureJournalEntry({bool record = true}) {
    if (_currentChanges == null) {
      return false;
    }
    completeChanges();

    // nuke remainder of journal, in case we weren't at the end
    journal.removeRange(_journalIndex, journal.length);

    // add the new changes to the journal
    if (record) {
      journal.add(_currentChanges);
    }

    // schedule those changes to be sent to other clients (and server for
    // saving)
    coopMakeChangeSet(_currentChanges, useFrom: false);
    _journalIndex = journal.length;
    _currentChanges = null;
    return true;
  }

  @protected
  @mustCallSuper
  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    if (!_isRecording) {
      return;
    }
    _currentChanges ??= CorePropertyChanges();
    _currentChanges.change(object, propertyKey, from, to);
  }

  @protected
  @mustCallSuper
  void changeAnimatedProperty(Core object, int propertyKey, bool autoKey) {
    var properties = _animationChanges[object.id] ??= {};
    properties.add(propertyKey);
  }

  void editorPropertyChanged(
      Core object, int propertyKey, Object from, Object to);

  /// Method called when a journal entry is created or applied via an undo/redo.
  @protected
  void completeChanges();

  /// Creates a connection to the co-op web socket server
  Future<ConnectResult> connect(String host, String path,
      [String token]) async {
    int clientId = await getIntSetting('clientId') ?? 0;
    _client?.dispose();
    _client = CoopClient(
      host,
      path,
      clientId: clientId,
      localSettings: this,
      token: token,
    )
      ..changesAccepted = changesAccepted
      ..changesRejected = changesRejected
      ..makeChanges = receiveCoopChanges
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
      }
      ..stateChanged = connectionStateChanged;

    // does this need to return anything?
    return _client.connect();
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
    var disconnectResult = false;
    if (_client != null) {
      disconnectResult = await _client.disconnect();
    }
    return disconnectResult;
  }

  void reconnect({bool now = false}) => _client.reconnect(now);

  Object getObjectProperty(Core object, int propertyKey);

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }

  @protected
  Change makeCoopChange(int propertyKey, Object value);

  @protected
  void resetAnimated(Core object, int propertyKey);

  @protected
  Core makeCoreInstance(int typeKey);

  /// Find Core objects of type [T].
  Iterable<T> objectsOfType<T>() => _objects.values.whereType<T>();

  void onAddedDirty(Core object);
  void onAddedClean(Core object);

  void onRemoved(Core object);

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

  @override
  void removeObject<T extends Core>(T object) {
    assert(object != null, 'Attempted to delete a null object');
    if (_objects.remove(object.id) == null) {
      // Object was already removed or not a part of this context.
      return;
    }
    object._isActive = false;
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
    object._changeListeners?.clear();
  }

  /// Find a Core object by id.
  @override
  T resolve<T>(Id id) {
    var object = _objects[id];
    if (object is T) {
      return object as T;
    }
    return null;
  }

  void setObjectProperty(Core object, int propertyKey, Object value);
  void setObjectPropertyCore(Core object, int propertyKey, Object value);

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

  void _holdObject(Core object) {
    object._isActive = true;
    _objects[object.id] = object;
  }

  void _applyJournalEntry(
    CorePropertyChanges changes, {
    bool isUndo,
    bool sendToCoop = true,
  }) {
    Set<Core> regeneratedObjects = {};

    // First regenerate objects before changing any property key anywhere in the
    // changeset.
    changes.entries.forEach((objectId, objectChanges) {
      var object = _objects[objectId];
      if (object == null) {
        var hydrateKey = isUndo ? removeKey : addKey;
        // The object may have been previously deleted, if so this change set
        // would have had an add key.
        entryLoop:
        for (final entry in objectChanges.entries) {
          if (entry.key == hydrateKey) {
            object = makeCoreInstance(entry.value.to as int);
            regeneratedObjects.add(object);
            object.id = objectId;
            object.context = this;
            _holdObject(object);
            break entryLoop;
          }
        }
      }
    });

    // Ok all objects have been regenerated, go ahead and change properties.
    changes.entries.forEach((objectId, objectChanges) {
      var object = _objects[objectId];
      if (object != null) {
        objectChanges.forEach((propertyKey, change) {
          if (propertyKey == addKey) {
            if (isUndo) {
              // Had an add key, this is undo, remove it.
              removeObject(object);
            }
          } else if (propertyKey == removeKey) {
            if (!isUndo) {
              // Had an remove key, this is redo, remove it.
              removeObject(object);
            }
          } else {
            // Need to re-write history (grab current value as the change.from).
            // We do this to patch-up history items that change when the server
            // sends changes from other clients (or previous changes get
            // rejected).
            if (isUndo) {
              change.to = getObjectProperty(object, propertyKey);
              setObjectPropertyCore(object, propertyKey, change.from);
            } else {
              change.from = getObjectProperty(object, propertyKey);
              setObjectPropertyCore(object, propertyKey, change.to);
            }
          }
        });
      }
      if (regeneratedObjects.contains(object)) {
        onAddedDirty(object);

        // var changes = CorePropertyChanges();
        // changes.change(object, addKey, removeKey, object.coreType);
        // object.changeNonNull(changes.change);
        // Now need to add it to coop
      }
    });

    if (sendToCoop) {
      coopMakeChangeSet(changes, useFrom: isUndo);
    }
    completeChanges();
    regeneratedObjects.forEach(onAddedClean);
  }

  /// Map of inflight[objectId][propertyKey][changeCount] to track whether
  /// there are still in-flight changes for an object. We need a changeCount as
  /// the property can be changed multiple times and shouldn't be removed from
  /// the set until it returns to 0.
  @protected
  final HashMap<Id, HashMap<int, int>> inflight =
      HashMap<Id, HashMap<int, int>>();

  @mustCallSuper
  @protected
  void changesAccepted(ChangeSet changes) {
    _log.finest("ACCEPTING ${changes.id}.");
    freshChanges.remove(changes);

    // Update the inflight counters for the properties.
    for (final objectChanges in changes.objects) {
      var objectInflightChanges =
          inflight[objectChanges.objectId] ??= HashMap<int, int>();
      for (final change in objectChanges.changes) {
        var value = objectInflightChanges[change.op];
        if (value != null) {
          var v = max(0, value - 1);
          if (v == 0) {
            objectInflightChanges.remove(change.op);
            if (objectInflightChanges.isEmpty) {
              inflight.remove(objectChanges.objectId);
            }
          } else {
            objectInflightChanges[change.op] = v;
          }
        }
      }
    }
    abandonChanges(changes);
  }

  @mustCallSuper
  @protected
  Future<void> changesRejected(ChangeSet changes) async {
    await _client.disconnect();
    clearJournal();
    await _client.connect();
  }

  bool isRuntimeProperty(int propertyKey);
  bool isCoopProperty(int propertyKey);

  /// Returns the [CoreFieldType] mapped to the [propertyKey].
  CoreFieldType coreType(int propertyKey);

  @protected
  ChangeSet coopMakeChangeSet(CorePropertyChanges changes, {bool useFrom}) {
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

      var objectInflightChanges = inflight[objectId] ??= HashMap<int, int>();

      // See if we just deleting this object. If so, there's no need to send all
      // the other property changes. Just send the delete change.
      if (changes.keys.any((key) => key == dehydrateKey)) {
        var change = makeCoopChange(removeKey, objectId);
        if (change != null) {
          objectChanges.changes.add(change);
        }
      } else {
        changes.forEach((key, entry) {
          if (!isCoopProperty(key)) {
            return;
          }
          objectInflightChanges[key] = (objectInflightChanges[key] ??= 0) + 1;
          if (key == hydrateKey) {
            var change = makeCoopChange(addKey, entry.to);
            if (change != null) {
              objectChanges.changes.add(change);
            }
          } else if (key == dehydrateKey) {
            assert(false, 'this should\'ve fallen into the delete path above');
          } else {
            var change = makeCoopChange(key, useFrom ? entry.from : entry.to);
            if (change != null) {
              objectChanges.changes.add(change);
            }
          }
        });
      }

      // Some change sets have only editor properties and result in an empty
      // changes list, no need to send it...
      if (objectChanges.changes.isNotEmpty) {
        sendChanges.objects.add(objectChanges);
      }
    });
    if (sendChanges.objects.isNotEmpty) {
      freshChanges[sendChanges] = FreshChange(changes, useFrom);
      _client?.queueChanges(sendChanges);
      persistChanges(sendChanges);
    }
    return sendChanges;
  }

  void persistChanges(ChangeSet changes);
  void abandonChanges(ChangeSet changes);

  void startAdd() {
    _delayAdd = [];
  }

  void completeAdd([bool forceEnableRecording = false]) {
    if (_delayAdd == null) {
      return;
    }
    var delayed = _delayAdd.toList(growable: false);
    _delayAdd = null;

    delayed.forEach(onAddedDirty);
    completeChanges();
    if (forceEnableRecording) {
      _isRecording = forceEnableRecording;
    }
    delayed.forEach(onAddedClean);
  }

  @protected
  @mustCallSuper
  void receiveCoopChanges(ChangeSet changes) {
    // We've received changes from Coop. Initialize the delayAdd list so that
    // onAdded doesn't get called as objects are created. We'll manually call it
    // at the end of this method once all the changes have been made.
    _log.finest("STARTING ADD");
    startAdd();

    // Track whether recording was on/off, definitely turn it off during these
    // changes.
    var wasRecording = _isRecording;
    _isRecording = false;

    for (final objectChanges in changes.objects) {
      // Check if this object has changes already in-flight.
      var objectInflight = inflight[objectChanges.objectId];
      if (objectInflight != null) {
        // prune out changes that are still waiting for acknowledge.
        List<Change> changesToApply = [];
        for (final change in objectChanges.changes) {
          var flightValue = objectInflight[change.op];
          // Only approve a change that doesn't have an inflight change.
          if (flightValue == null || flightValue == 0) {
            changesToApply.add(change);
          }
        }
        objectChanges.changes = changesToApply;
      }
      applyCoopChanges(objectChanges);
    }
    completeAdd(wasRecording);
  }

  /// Helper to determine if a batch add operation is in progress.
  bool get isBatchAdding => _delayAdd != null;

  bool get isRecording => _isRecording;

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

    // Let's allow nesting batchAdd callbacks.
    if (isBatchAdding) {
      // Already in a batch add, just piggy back...
      addCallback();
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
    _players.clear();
    for (final object in _objects.values) {
      object._isActive = false;
    }
    _objects.clear();
    freshChanges.clear();
    inflight.clear();
  }

  /// Clear the undo stack.
  void clearJournal() {
    _journalIndex = 0;
    journal.clear();
  }

  double _lastCursorX = 0, _lastCursorY = 0;
  void cursorMoved(double x, double y) {
    _lastCursorX = x;
    _lastCursorY = y;
    debounce(_sendLastCursor, duration: const Duration(milliseconds: 33));
  }

  void _sendLastCursor() {
    if (_client == null || !_client.isConnected) {
      return;
    }

    _client.sendCursor(_lastCursorX, _lastCursorY);
  }

  @mustCallSuper
  void connectionStateChanged(CoopConnectionStatus status) {
    switch (status.state) {
      case CoopConnectionState.connected:
        // In test setups _client doesnt always exist.
        if (_client == null) {
          return;
        }
        int maxId = 0;

        for (final object in _objects.values) {
          if (object.id.client == _client.clientId) {
            if (object.id.object >= maxId) {
              maxId = object.id.object;
            }
          }
        }
        _nextObjectId = Id(_client.clientId, maxId + 1);

        // Load is complete, we can now process any deferred batch add
        // operations.
        if (_deferredBatchAdd != null) {
          var deferred = Set<BatchAddCallback>.from(_deferredBatchAdd);
          _deferredBatchAdd = null;
          deferred.forEach(batchAdd);
        }
        break;
      default:
        break;
    }
  }

  void _skipProperty(BinaryReader reader, int propertyKey,
      HashMap<int, CoreFieldType> propertyToField) {
    var field = propertyToField[propertyKey];
    if (field == null) {
      throw UnsupportedError('Unsupported property key $propertyKey. '
          'A new runtime is likely necessary to play this file.');
    }
    // Desrialize but don't do anything with the contents...
    field.runtimeDeserialize(reader);
  }

  T readRuntimeObject<T extends Core<CoreContext>>(
      BinaryReader reader, HashMap<int, CoreFieldType> propertyToField,
      [Iterable<RuntimeRemap> remaps]) {
    int coreObjectKey = reader.readVarUint();

    var object = makeCoreInstance(coreObjectKey);

    while (true) {
      int propertyKey = reader.readVarUint();
      if (propertyKey == 0) {
        // Terminator. https://media.giphy.com/media/7TtvTUMm9mp20/giphy.gif
        break;
      }

      var fieldType = coreType(propertyKey);
      if (fieldType == null || object == null) {
        _skipProperty(reader, propertyKey, propertyToField);
      } else {
        bool remapped = false;
        if (remaps != null) {
          for (final remap in remaps) {
            if (fieldType == remap?.fieldType) {
              // Id fields get remapped so we read them in as integers allowing
              // an external process to then map those integers to those ids.
              // This should be done before the batch add wrapping this entire
              // operation completes.
              if (remap.add(object, propertyKey, reader)) {
                remapped = true;
                break;
              }
            }
          }
        }

        if (!remapped) {
          // This will attempt to set the object property, but failure here is
          // acceptable.
          setObjectPropertyCore(
              object, propertyKey, fieldType.runtimeDeserialize(reader));
        }
      }
    }
    return object as T;
  }

  void restoreRevision(int revisionId) => _client.restoreRevision(revisionId);
}

class FreshChange {
  final CorePropertyChanges change;
  final bool useFrom;

  const FreshChange(this.change, this.useFrom);
}

class RuntimeRemapProperty<T> {
  Core<CoreContext> object;
  int propertyKey;
  T value;
  RuntimeRemapProperty(this.object, this.propertyKey, this.value);
}

abstract class RuntimeRemap<T, K> {
  final CoreFieldType<K> fieldType;
  final CoreFieldType<T> runtimeFieldType;

  Set<RuntimeRemapProperty<T>> properties = {};

  RuntimeRemap(this.fieldType, this.runtimeFieldType);

  bool add(Core<CoreContext> object, int propertyKey, BinaryReader reader);
}
