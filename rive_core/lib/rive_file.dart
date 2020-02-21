import 'package:core/coop/change.dart';
import 'package:core/coop/player.dart';
import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'artboard.dart';
import 'component.dart';
import 'container_component.dart';
import 'src/generated/rive_core_context.dart';
import 'src/isolated_persist.dart';

class RiveFile extends RiveCoreContext {
  final String name;
  final Map<String, dynamic> overridePreferences;
  final bool useSharedPreferences;
  final List<Artboard> artboards = [];
  final Set<RiveFileDelegate> delegates = {};
  int _dirt = 0;
  final IsolatedPersist _isolatedPersist;
  final RiveApi api;
  final Set<ClientSidePlayer> _dirtyPlayers = {};

  final ValueNotifier<Iterable<ClientSidePlayer>> allPlayers =
      ValueNotifier<Iterable<ClientSidePlayer>>([]);

  /// Set of components that need to be resorted after the current operation
  /// (undo/redo/capture) completes.
  final Set<ContainerComponent> _needChildSort = {};

  /// Set of components that need to their dependencies re-built.
  final Set<Component> _needDependenciesBuilt = {};

  /// Set of artboards that need their dependencies sorted.
  final Set<Artboard> _needDependenciesOrdered = {};

  /// Set of components that have had dependents changes and should recompute
  /// their dependentIds once the dependencies have been recomputed.
  final Set<Component> _needDependentIdsRebuilt = {};

  SharedPreferences _prefs;

  RiveFile(
    String fileId,
    this.name, {
    this.api,
    this.overridePreferences,
    this.useSharedPreferences = true,
  })  : _isolatedPersist = IsolatedPersist(fileId),
        super(fileId);

  @override
  void abandonChanges(ChangeSet changes) {
    _isolatedPersist.remove(changes);
  }

  bool addDelegate(RiveFileDelegate delegate) => delegates.add(delegate);

  bool advance(double elapsed) {
    cleanDirt();
    bool advanced = false;
    for (final artboard in artboards) {
      if (artboard.advance(elapsed)) {
        advanced = true;
      }
    }
    return advanced;
  }

  /// Perform any cleanup required due to properties being marked dirty.
  bool cleanDirt([int escapeHatch = 0]) {
    assert(escapeHatch < 1000);
    if (_dirt == 0) {
      return false;
    }
    print("CLEAN!");
    _dirt = 0;

    // Copy it in case it is changed during the building (meaning this process
    // needs to recurse).
    Set<Component> needDependenciesBuilt =
        Set<Component>.from(_needDependenciesBuilt);
    _needDependenciesBuilt.clear();

    // First resolve the artboards
    for (final component in needDependenciesBuilt) {
      component.resolveArtboard();
    }

    // Then build the dependencies
    for (final component in needDependenciesBuilt) {
      if (component.artboard != null) {
        _needDependenciesOrdered.add(component.artboard);
        print("Component with good artboard ${component.name}");
      } else {
        print("WHY IS THE ARTBOARD NULL $component ${component.name}??");
      }
      component.buildDependencies();
    }

    // Rebuild any dependent ids that will have changed from building
    // dependencies.
    for (final component in _needDependentIdsRebuilt) {
      component.dependentIds =
          component.dependents.map((other) => other.id).toList(growable: false);
    }
    _needDependentIdsRebuilt.clear();

    for (final parent in _needChildSort) {
      parent.children.sortFractional();
    }
    _needChildSort.clear();

    // finally sort dependencies
    for (final artboard in _needDependenciesOrdered) {
      artboard.sortDependencies();
    }
    _needDependenciesOrdered.clear();

    if (_dirt != 0) {
      cleanDirt(escapeHatch + 1);
      return true;
    }

    // Only call dirt cleaned when it's really finally cleaned.
    delegates.forEach((delegate) => delegate.onDirtCleaned());
    return true;
  }

  @override
  void completeChanges() {
    cleanDirt();
  }

  @override
  Future<int> getIntSetting(String key) async {
    if (overridePreferences != null) {
      dynamic val = overridePreferences[key];
      if (val is int) {
        return val;
      }
    }
    if (!useSharedPreferences) {
      return null;
    }
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs.getInt(key);
  }

  @override
  Future<List<ChangeSet>> getOfflineChanges() => _isolatedPersist.changes();

  @override
  Future<String> getStringSetting(String key) async {
    if (overridePreferences != null) {
      dynamic val = overridePreferences[key];
      if (val is String) {
        return val;
      }
    }
    if (!useSharedPreferences) {
      return null;
    }
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs.getString(key);
  }

  /// Mark a component as needing its children to be sorted.
  void markChildSortDirty(ContainerComponent component) {
    _dirt |= _RiveDirt.childSort;
    _needChildSort.add(component);
  }

  /// Mark a component as needing its artboard to be resolved.
  void markDependenciesDirty(Component component) {
    _dirt |= _RiveDirt.dependencies;
    _needDependenciesBuilt.add(component);
    markNeedsAdvance();
  }

  /// Mark an artboard as needing its dependencies sorted.
  void markDependencyOrderDirty(Artboard artboard) {
    _dirt |= _RiveDirt.dependencyOrder;
    _needDependenciesOrdered.add(artboard);
  }

  /// Mark a component as needing its dependent ids recalculated.
  void markDependentIdsDirty(Component component) {
    _needDependentIdsRebuilt.add(component);
  }

  void markNeedsAdvance() =>
      delegates.forEach((delegate) => delegate.markNeedsAdvance());

  @override
  void onAddedDirty(Component object) {
    print("ADDING ${object.name} ${object.id} ${object.parentId}");
    if (object.parentId != null) {
      object.parent = object.context?.resolve(object.parentId);
      if (object.parent == null) {
        print("Failed to resolve parent with id ${object.parentId}");
      } else {
        object.parent.childAdded(object);
      }
    }
  }

  @override
  void onAddedClean(Component object) {
    delegates.forEach((delegate) => delegate.onObjectAdded(object));
    if (object is Artboard) {
      artboards.add(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  void onRemoved(Component object) {
    object.onRemoved();
    delegates.forEach((delegate) => delegate.onObjectRemoved(object));
    if (object is Artboard) {
      artboards.remove(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  void onWipe() {
    artboards.clear();
    delegates.forEach((delegate) => delegate.onWipe());
    _isolatedPersist.wipe();
  }

  @override
  void persistChanges(ChangeSet changes) {
    _isolatedPersist.add(changes);
  }

  bool removeDelegate(RiveFileDelegate delegate) => delegates.remove(delegate);

  @override
  Future<void> setIntSetting(String key, int value) async {
    if (!useSharedPreferences) {
      return;
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setStringSetting(String key, String value) async {
    if (!useSharedPreferences) {
      return;
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setString(key, value);
  }

  @override
  Player makeClientSidePlayer(Player serverPlayer) =>
      ClientSidePlayer(serverPlayer);

  @override
  void onPlayerAdded(ClientSidePlayer player) {
    _dirtyPlayers.add(player);
  }

  Future<void> _loadDirtyPlayers() async {
    if (_dirtyPlayers.isEmpty) {
      return;
    }
    var artists = RiveArtists(api);

    var loadingPlayers = _dirtyPlayers.toList(growable: false);
    // make a unique set of owner ids (owners can have multiple players).
    var loadList = Set<int>.from(
        loadingPlayers.map((player) => player.ownerId).toList(growable: false));

    // Make sure to clear dirty players before awaiting so no async op changes
    // this list before we clear it.
    _dirtyPlayers.clear();

    var users = await artists.list(loadList);
    if (users != null) {
      for (final user in users) {
        // Could build up a map above if this gets prohibitive.
        for (final player in loadingPlayers) {
          if (player.ownerId == user.ownerId) {
            player.user.value = user;
          }
        }
      }
    }
  }

  @override
  void onPlayerRemoved(ClientSidePlayer player) {
    _dirtyPlayers.remove(player);
  }

  @override
  void onPlayersChanged() {
    allPlayers.value = players.cast<ClientSidePlayer>();

    // Loading the active player list is low priority compared to other stuff
    // happening (like loading assets or content for the file) so we debounce it
    // pretty heavily.
    debounce(_loadDirtyPlayers, duration: const Duration(milliseconds: 300));
  }
}

/// Delegate type that can be passed to [RiveFile] to listen to events.
abstract class RiveFileDelegate {
  void markNeedsAdvance();
  void onArtboardsChanged() {}
  void onDirtCleaned();
  void onObjectAdded(Core object) {}
  void onObjectRemoved(Core object) {}

  /// Called when the entire file is wiped as data is about to load/reload.
  void onWipe();
}

class _RiveDirt {
  static const int dependencies = 1 << 0;
  static const int childSort = 1 << 1;
  static const int dependencyOrder = 1 << 2;
}
