import 'dart:async';
import 'dart:collection';

import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';

class SizedMap<K, V> {
  final Map<K, V> _map;
  final Queue<K> _orderedKeys;
  final int size;

  SizedMap(this.size)
      : _map = <K, V>{},
        _orderedKeys = Queue<K>();

  V operator [](K key) => _map[key];

  void operator []=(K key, V value) {
    _map[key] = value;
    _orderedKeys.add(key);
    _trim();
  }

  void _trim() {
    if (_map.length > size) {
      var keys = _orderedKeys.take(size - _map.length);
      keys.forEach(_map.remove);
    }
  }
}

/// General manager for general ui things
class TaskManager with Subscriptions {
  static final TaskManager _instance = TaskManager._();
  factory TaskManager() => _instance;

  final SizedMap<String, TaskCompleted> cache = SizedMap(100);
  final taskCompleters = <TaskCompleter>{};

  TaskManager._() {
    _attach();
  }

  TaskManager.tester() {
    _attach();
  }

  void _attach() {
    subscribe<TaskCompleted>(_taskCompleted);
  }

  void _taskCompleted(TaskCompleted completedTask) {
    cache[completedTask.taskId] = completedTask;
    taskCompleters.forEach((TaskCompleter taskCompleter) {
      taskCompleter.add(completedTask);
    });
  }

  Completer notifyTasks(Set<String> taskIds, Function(TaskCompleted) callback) {
    var taskCompleter = TaskCompleter(taskIds, callback);
    taskCompleters.add(taskCompleter);
    removeCompleter(taskCompleter);
    return taskCompleter.completer;
  }

  Future<void> removeCompleter(TaskCompleter taskCompleter) async {
    await taskCompleter.completer.future;
    taskCompleters.remove(taskCompleter);
  }
}

class TaskCompleter {
  final Set<String> taskIds;
  final Function(TaskCompleted) callback;
  final completer = Completer<Set<TaskCompleted>>();

  final tasksCompleted = <TaskCompleted>{};

  TaskCompleter(this.taskIds, this.callback);

  Future<void> add(TaskCompleted action) async {
    var complete = false;
    if (taskIds.contains(action.taskId)) {
      await callback(action);
      tasksCompleted.add(action);
      if (tasksCompleted.length == taskIds.length) {
        completer.complete(tasksCompleted);
        complete = true;
      }
    }
    return complete;
  }
}
