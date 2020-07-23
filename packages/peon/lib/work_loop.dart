import 'package:peon/src/queue.dart';
import 'package:peon/src/tasks/base.dart';
import 'package:peon/src/worker.dart';

Future<void> main() async {
  const registeredTasks = <String, Task Function(Map<String, dynamic>)>{};
  registeredTasks['ping'] = PingTask.fromData;
  registeredTasks['echo'] = EchoTask.fromData;

  await loop(getQueue, registeredTasks);
}
