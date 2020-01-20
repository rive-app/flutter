import 'package:core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'artboard.dart';
import 'src/generated/rive_core_context.dart';

/// Delegate type that can be passed to [RiveFile] to listen to events.
abstract class RiveFileDelegate {
  void onArtboardsChanged() {}
  void onObjectAdded(Core object) {}
  void onObjectRemoved(Core object) {}
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
    // Make sure we've updated dependents if some change occurred to them.
    if(_dirt & RiveDirt.dependencies != 0)
    {
      
    }
    return super.captureJournalEntry();
  }

  void markDependenciesDirty() {
    _dirt |= RiveDirt.dependencies;
  }
}
