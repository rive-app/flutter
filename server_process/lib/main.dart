// import 'package:core/coop/coop_server.dart';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coop_server_library/server.dart';
import 'package:logging/logging.dart';

const String dataFolder = 'data-folder';

void _configureLogging() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  // Printing to console for the momemt
  Logger.root.onRecord.listen((r) {
    print('${r.level.name}: ${r.time}: ${r.message}');
  });
}

Future<void> main(List<String> arguments) async {
  // Logging config for the co-op server
  _configureLogging();
  final Logger log = Logger('CoopServer');

  final parser = ArgParser()..addOption(dataFolder, abbr: 'd');

  var argResults = parser.parse(arguments);
  var path = argResults[dataFolder] as String;
  log.finest('data-folder path: $path');
  var server = RiveCoopServer();
  var result = await server.listen(
    port: 8000,
    options: {
      'data-dir': path,
    },
  );
  log.info('Server has started: $result');

  // Register with the 2D server
  final success = await server.register();
  if (!success) {
    log.severe('Unable to register with 2D service');
    exit(1);
  } else {
    log.info('Successfully registered with 2D service');
  }

  // Try to intercept shutdown signals (e.g. CTRL-C) and
  // deregister the server
  ProcessSignal.sigint.watch().listen((signal) async {
    log.info('SIGINT received');
    await server.deregister()
        ? log.info('Deregistered from 2D service')
        : log.severe('Error deregistering from 2D service');
    exit(1);
  });
}
