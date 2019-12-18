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

class CoreContext {
  final Map<int, Core> objects = <int, Core>{};
  final List<Map<int, Map<int, ChangeEntry>>> journal =
      <Map<int, Map<int, ChangeEntry>>>[];

  Map<int, Map<int, ChangeEntry>> currentChanges;

  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    currentChanges ??= <int, Map<int, ChangeEntry>>{};
    var changes = currentChanges[object.id];
    if (changes == null) {
      currentChanges[object.id] = changes = <int, ChangeEntry>{};
    }
    var change = changes[propertyKey];
    if (change == null) {
      changes[propertyKey] = change = ChangeEntry(from, to);
    } else {
      change.to = to;
    }

    // int value = 3;
    // switch(value)
    // {
    //   case 0:
    //   case 2:
    //   case 4:
    //     print("serialize num");
    //     break;
    //   case 1:
    //   case 3:
    //     print("serialize string");
    //     break;
    // }
    //object.id
  }

  T add<T extends Core>(T object){
    object.id ??= localId--;
    return object;
  }

  void remove<T extends Core>(T object) {
    
  }
}

int localId = 0;

class Core {
  int id;
  CoreContext context;
}
