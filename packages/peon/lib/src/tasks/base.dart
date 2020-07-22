import 'package:utilities/deserialize.dart';

class IllegalTask implements Exception {
  String issue;
  IllegalTask(this.issue);
}

mixin Task {
  Future<bool> execute();
}

class PingTask with Task {
  PingTask();

  // NOTE: im doing this so i can 'register' task
  // ignore: prefer_constructors_over_static_methods
  static PingTask fromData(Map<String, dynamic> data) {
    return PingTask();
  }

  @override
  Future<bool> execute() async {
    print('pinged');
    return true;
  }
}

class EchoTask with Task {
  final String message;
  EchoTask({this.message});

  // NOTE: im doing this so i can 'register' task
  // ignore: prefer_constructors_over_static_methods
  static EchoTask fromData(Map<String, dynamic> data) {
    if (!data.containsKey("params")) {
      throw IllegalTask(
          "Expecting a JSON structure with `params` but got $data");
    }

    var params = data.getMap<String, Object>('params');
    return EchoTask(message: params.getString('message'));
  }

  @override
  Future<bool> execute() async {
    print(message);
    return true;
  }
}
