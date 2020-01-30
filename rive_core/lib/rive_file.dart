import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'artboard.dart';
import 'component.dart';
import 'container_component.dart';
import 'src/generated/rive_core_context.dart';

/// Delegate type that can be passed to [RiveFile] to listen to events.
abstract class RiveFileDelegate {
  void onArtboardsChanged() {}
  void onObjectAdded(Core object) {}
  void onObjectRemoved(Core object) {}
  void onDirtCleaned();
  void markNeedsAdvance();
}

class _RiveDirt {
  static const int dependencies = 1 << 0;
  static const int childSort = 1 << 1;
  static const int dependencyOrder = 1 << 2;
}

class RiveFile extends RiveCoreContext {
  final Map<String, dynamic> overridePreferences;
  final bool useSharedPreferences;
  final List<Artboard> artboards = [];
  final Set<RiveFileDelegate> delegates = {};
  int _dirt = 0;

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

  /// Mark a component as needing its children to be sorted.
  void markChildSortDirty(ContainerComponent component) {
    _dirt |= _RiveDirt.childSort;
    _needChildSort.add(component);
  }

  /// Mark as an artboard as needing its dependencies sorted.
  void markDependencyOrderDirty(Artboard artboard) {
    _dirt |= _RiveDirt.dependencyOrder;
    _needDependenciesOrdered.add(artboard);
  }

  /// Mark a component as needing its artboard to be resolved.
  void markDependenciesDirty(Component component) {
    _dirt |= _RiveDirt.dependencies;
    _needDependenciesBuilt.add(component);
    markNeedsAdvance();
  }

  /// Mark a component as needing its dependent ids recalculated.
  void markDependentIdsDirty(Component component) {
    _needDependentIdsRebuilt.add(component);
  }

  /// Perform any cleanup required due to properties being marked dirty.
  bool cleanDirt([int escapeHatch = 0]) {
    assert(escapeHatch < 1000);
    if (_dirt == 0) {
      return false;
    }
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
      _needDependenciesOrdered.add(component.artboard);
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
  void completeJournalOperation() {
    cleanDirt();
  }

  RiveFile(String fileId,
      {this.overridePreferences, this.useSharedPreferences = true})
      : super(fileId);

  SharedPreferences _prefs;

  bool addDelegate(RiveFileDelegate delegate) => delegates.add(delegate);
  bool removeDelegate(RiveFileDelegate delegate) => delegates.remove(delegate);

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
  Future<void> setIntSetting(String key, int value) async {
    if (!useSharedPreferences) {
      return;
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setInt(key, value);
  }

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

  @override
  Future<void> setStringSetting(String key, String value) async {
    if (!useSharedPreferences) {
      return;
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setString(key, value);
  }

  @override
  void onAdded(Component object) {
    print("ADDED OBJECT $object ${object.parent}");
    if (object.parentId != null) {
      print("REOSLVE ${object.parentId}");
      object.parent = object.context?.resolve(object.parentId);
      // object.parent.children.add(object);
      object.parent.childAdded(object);
    }
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

  void markNeedsAdvance() =>
      delegates.forEach((delegate) => delegate.markNeedsAdvance());

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
}
