import 'package:peon/src/queue.dart';
import 'package:peon/src/worker.dart';

Future<void> main() async {
  await loop(getQueue());
}
