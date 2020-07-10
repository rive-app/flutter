import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:peon/src/queue.dart';

Future<void> main(List<String> arguments) async {
  // e.g
  // AWS_ACCESS_KEY=<> AWS_SECRET_KEY=<> AWS_QUEUE=https://sqs.us-west-1.amazonaws.com/654831454668/tester dart lib/pumper.dart --help

  var runner = CommandRunner<dynamic>("pumper", "Beastly task driver.")
    ..addCommand(PingCommand())
    ..addCommand(EchoCommand())
    ..addCommand(MakeFile());

  await runner.run(arguments); // Ca

  exit(0);
}

class PingCommand extends Command<dynamic> {
  @override
  final name = "ping";
  @override
  final description = "Simply ping our peons to let them know we're watching.";

  PingCommand();

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = getQueue();
    await queue.sendMessage(json.encode({"action": "ping"}));
  }
}

class MakeFile extends Command<dynamic> {
  @override
  final name = "makefile";
  @override
  final description = "Tell the peons to make a standard rive file, they're "
      "not that creative so dont expect much.";

  MakeFile();

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = getQueue();
    await queue.sendMessage(json.encode({"action": "makefile"}));
  }
}

class EchoCommand extends Command<dynamic> {
  @override
  final name = "echo";
  @override
  final description = "Get the peons to say what we say.";

  EchoCommand() {
    argParser.addOption('message',
        defaultsTo: "Work, work",
        help: "The message you want the peons to say");
  }

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = getQueue();

    await queue.sendMessage(json.encode({
      "action": "echo",
      "params": {"message": argResults["message"] as String}
    }));
  }
}
