import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http_client/console.dart';
import 'package:peon/src/queue.dart';

Future<void> main(List<String> arguments) async {
  // e.g
  // AWS_ACCESS_KEY=<> AWS_SECRET_KEY=<> AWS_DART_QUEUE=<> AWS_JS_QUEUE=<> dart lib/pumper.dart --help

  var runner = CommandRunner<dynamic>('pumper', 'Beastly task driver.')
    ..addCommand(PingCommand())
    ..addCommand(EchoCommand())
    ..addCommand(SvgToRive())
    ..addCommand(RiveToPNG());

  await runner.run(arguments);

  exit(0);
}

class PingCommand extends Command<dynamic> {
  @override
  final name = 'ping';
  @override
  final description = 'Simply ping our peons to let them know we\'re watching.';

  PingCommand();

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = await getQueue(ConsoleClient());
    await queue.sendMessage(json.encode({'action': 'ping'}));
  }
}

class EchoCommand extends Command<dynamic> {
  @override
  final name = 'echo';
  @override
  final description = 'Get the peons to say what we say.';

  EchoCommand() {
    argParser.addOption('message',
        defaultsTo: 'Work, work',
        help: 'The message you want the peons to say');
  }

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = await getQueue(ConsoleClient());

    await queue.sendMessage(json.encode({
      'action': 'echo',
      'params': {'message': argResults['message'] as String}
    }));
  }
}

class SvgToRive extends Command<dynamic> {
  @override
  final name = 'svgtorive';
  @override
  final description = 'Get the peons to say what we say.';

  SvgToRive() {
    argParser.addOption('sourceLocation',
        defaultsTo: 'https://source.location',
        help: 'Where to get the svg file from');
    argParser.addOption('targetLocation',
        defaultsTo: 'https://target.location',
        help: 'Where to put the rive file');
    argParser.addOption('notifyUserId', help: 'Where to put the rive file');
  }

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = await getQueue(ConsoleClient());

    await queue.sendMessage(json.encode({
      'action': 'svgtorive',
      'params': {
        'sourceLocation': argResults['sourceLocation'] as String,
        'targetLocation': argResults['targetLocation'] as String,
        'notifyUserId': int.parse(argResults['notifyUserId'] as String)
      }
    }));
  }
}

class RiveToPNG extends Command<dynamic> {
  @override
  final name = 'rivetopng';
  @override
  final description = 'Get the peons to say what we say.';

  RiveToPNG() {
    argParser.addOption('sourceLocation',
        defaultsTo: 'https://source.location',
        help: 'Where to get the coop file from');
    argParser.addOption('targetLocation',
        defaultsTo: 'https://target.location',
        help: 'Where to put the png file');
    argParser.addOption('fileId', help: 'who to tell about it');
    argParser.addOption('revisionId', help: 'who to tell about it');
    argParser.addOption('ownerId', help: 'who to tell about it');
  }

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    var queue = await getQueue(ConsoleClient());

    await queue.sendMessage(json.encode({
      'action': name,
      'params': {
        'fileId': int.parse(argResults['fileId'] as String),
        'revisionId': int.parse(argResults['revisionId'] as String),
        'ownerId': int.parse(argResults['ownerId'] as String),
        'sourceLocation': argResults['sourceLocation'] as String,
        'targetLocation': argResults['targetLocation'] as String
      }
    }));
  }
}
