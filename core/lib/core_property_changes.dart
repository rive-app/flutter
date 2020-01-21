import 'core.dart';

class ChangeEntry {
  Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

class CorePropertyChanges {
  final Map<int, Map<int, ChangeEntry>> entries = {};

  void change<T>(Core object, int propertyKey, T from, T to) {
    var changes = entries[object.id];
    if (changes == null) {
      entries[object.id] = changes = <int, ChangeEntry>{};
    }
    var change = changes[propertyKey];
    if (change == null) {
      changes[propertyKey] = change = ChangeEntry(from, to);
    } else {
      change.to = to;
    }
  }

  void changeId(int from, int to) {
    var objectChanges = entries[from];
    // Remap to new id
    if (objectChanges != null) {
      entries.remove(from);
      entries[to] = objectChanges;
    }
  }
}
