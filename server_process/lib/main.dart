// import 'package:core/coop/coop_server.dart';
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coop_server_library/server.dart';
import 'package:logging/logging.dart';

const dataFolder = 'data-folder';
const isProxied = 'proxied';

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

  final parser = ArgParser()
    ..addOption(dataFolder, abbr: 'd')
    ..addFlag(isProxied, abbr: 'p', defaultsTo: false);

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

  // Enable proxy support if asked
  if (argResults[isProxied] as bool) {
    log.info('Starting co-op server in proxy mode');

    // Register with the 2D service. If this fails,
    // shut down the co-op server
    final success = await server.register();
    if (!success) {
      log.severe('Unable to register with 2D service');
      exit(1);
    } else {
      log.info('Successfully registered with 2D service');
    }

    // Start a heartbeat check with the 2D service
    // Sends a heartbeat ping every 5 minutes
    final heartbeatTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => server.heartbeat(),
    );

    // Intercept shutdown signals (e.g. CTRL-C) and
    // deregister the server before shutting down
    ProcessSignal.sigint.watch().listen((signal) async {
      log.info('SIGINT received');
      await server.deregister()
          ? log.info('Deregistered from 2D service')
          : log.severe('Error deregistering from 2D service');
      heartbeatTimer.cancel();
      exit(1);
    });
  }
}
