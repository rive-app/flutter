import 'dart:io';

import 'package:peon/src/queue.dart';

Future<void> main(List<String> arguments) async {
  // e.g
  // AWS_ACCESS_KEY=<> AWS_SECRET_KEY=<> AWS_QUEUE=https://sqs.us-west-1.amazonaws.com/654831454668/tester dart lib/pumper.dart '{"action":"makefile"}'
  var queue = getQueue();

  if (arguments.length != 1) {
    throw Exception('Expecting exactly one argument, the payload');
  }
  await queue.sendMessage(arguments[0]);
  exit(0);
}
