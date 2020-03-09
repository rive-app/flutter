// import 'package:core/coop/coop_server.dart';
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coop_server_library/server.dart';
import 'package:logging/logging.dart';
import 'package:sentry/sentry.dart';

const dataFolder = 'data-folder';
const isProxied = 'proxied';

/// Configure logging options
void _configureLogging() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  // Printing to console for the momemt
  Logger.root.onRecord.listen((r) {
    print('${r.level.name}: ${r.time}: ${r.message}');
  });
}

final log = Logger('coop_server');

// Sentry config
// TODO: move this to a singleton?
const dsn = 'https://cd4c5a674f8e44f49203ce39d47c236c@sentry.io/3876713';
final sentry = SentryClient(dsn: dsn);

// Run the app in a zone so that uncaught errors and exceptions
// can be captured and logged. Then crash hard.
void main(List<String> arguments) {
  _configureLogging();
  runZoned(
    () => server(arguments),
    onError: (Object error, StackTrace stackTrace) async {
      log.severe('Crashing on: $error');
      try {
        await sentry.captureException(
          exception: error,
          stackTrace: stackTrace,
        );
        exit(1);
      } on Exception catch (e) {
        log.severe('Sending report to sentry.io failed: $e');
        exit(1);
      }
    },
  );
}

Future<void> server(List<String> arguments) async {
  // Logging config for the co-op server

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
  log.info('Co-op server has started: $result');

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

  // Shutdown function: called when some sort
  // of shutdown signal is received. Will
  // attempt to deregister before dying.

  Future shutdown(ProcessSignal signal) async {
    log.info('$signal received');
    await server.deregister()
        ? log.info('Deregistered from 2D service')
        : log.severe('Error deregistering from 2D service');
    heartbeatTimer.cancel();
    exit(1);
  }

  // Intercept shutdown signals (e.g. CTRL-C) and
  // deregister the server before shutting down
  try {
    ProcessSignal.sigint.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    log.info('Signal SIGINT is not supported by this service');
  }
  try {
    ProcessSignal.sigterm.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    log.info('Signal SIGTERM is not supported by this service');
  }
  try {
    ProcessSignal.sigkill.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    log.info('Signal SIGKILL is not supported by this service');
  }
}
