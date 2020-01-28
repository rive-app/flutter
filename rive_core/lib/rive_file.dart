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
}

class RiveDirt {
  static const int dependencies = 1 << 0;
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

  /// Set of components that need to their artboard resolved after the current
  /// operation (undo/redo/capture) completes.
  final Set<Component> _needResolveArtboard = {};

  /// Mark a component as needing its children to be sorted.
  void markChildSortDirty(ContainerComponent component) =>
      _needChildSort.add(component);

  /// Mark a component as needing its artboard to be resolved.
  void markArtboardDirty(Component component) =>
      _needResolveArtboard.add(component);

  /// Perform any cleanup required due to properties being marked dirty.
  void cleanDirt() {
    if(_needResolveArtboard.isEmpty && _needChildSort.isEmpty) {
      return;
    }
    for (final component in _needResolveArtboard) {
      component.resolveArtboard();
    }
    for (final parent in _needChildSort) {
      parent.children.sortFractional();
    }
    _needChildSort.clear();
    _needResolveArtboard.clear();

    delegates.forEach((delegate) => delegate.onDirtCleaned());
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
  void onAdded(Core object) {
    delegates.forEach((delegate) => delegate.onObjectAdded(object));
    if (object is Artboard) {
      artboards.add(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  void onRemoved(Core object) {
    delegates.forEach((delegate) => delegate.onObjectRemoved(object));
    if (object is Artboard) {
      artboards.remove(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  bool captureJournalEntry() {
    print("CAP");
    // Make sure we've updated dependents if some change occurred to them.
    if (_dirt & RiveDirt.dependencies != 0) {}
    return super.captureJournalEntry();
  }

  void markDependenciesDirty() {
    _dirt |= RiveDirt.dependencies;
  }
}
