// import 'package:core/coop/coop_server.dart';
import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'package:coop_server_library/server.dart';
import 'package:utilities/logger.dart';

const dataFolder = 'data-folder';

final _log = Logger('coop_server');

// Run the app in a zone so that uncaught errors and exceptions
// can be captured and logged. Then crash hard.
void main(List<String> arguments) {
  configureLogger();
  runZoned(() => server(arguments),
      onError: (Object error, StackTrace stackTrace) async {
    _log.severe('Crashing on: $error', error, stackTrace);
    sleepyExit(1);
  });
}

Future<void> server(List<String> arguments) async {
  // Logging config for the co-op server

  final parser = ArgParser()..addOption(dataFolder, abbr: 'd');

  var argResults = parser.parse(arguments);
  var path = argResults[dataFolder] as String;
  _log.finest('data-folder path: $path');
  var server = RiveCoopServer();
  var result = await server.listen(
    port: 8000,
    options: {
      'data-dir': path,
    },
  );
  _log.info('Co-op server has started: $result');

  // Register with the 2D service. If this fails,
  // shut down the co-op server
  final success = await server.register();
  if (!success) {
    _log.info('Unable to register with 2D service');
    sleepyExit(1);
  } else {
    _log.info('Successfully registered with 2D service');
  }

  // Start a heartbeat check with the 2D service
  // Sends a heartbeat ping every 30 seconds
  final heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
    // Fetch free memory if possible
    final memData = await _meminfo();
    server.heartbeat(memData);
  });

  // Shutdown function: called when some sort
  // of shutdown signal is received. Will
  // attempt to deregister before dying.

  Future shutdown(ProcessSignal signal) async {
    _log.info('$signal received');
    await server.deregister()
        ? _log.info('Deregistered from 2D service')
        : _log.info('Error deregistering from 2D service');
    heartbeatTimer.cancel();
    sleepyExit(1);
  }

  // Intercept shutdown signals (e.g. CTRL-C) and
  // deregister the server before shutting down
  try {
    ProcessSignal.sigint.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    _log.info('Signal SIGINT is not supported by this service');
  }
  try {
    ProcessSignal.sigterm.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    _log.info('Signal SIGTERM is not supported by this service');
  }
  try {
    ProcessSignal.sigkill.watch().listen((signal) async {
      await shutdown(signal);
    });
  } on SignalException catch (_) {
    _log.info('Signal SIGKILL is not supported by this service');
  }
}

/// Attempts to get memory info from the underlying OS
/// If it fails, it returns null.
Future<Map<String, String>> _meminfo() async {
  // Converts memory size to MB if necessary
  int _calculateMemorySize(int value, String symbol) {
    if (symbol.toLowerCase() == 'kb') {
      return value ~/ 1024;
    }
    return value;
  }

  // Parses a line from /proc/meminfo
  int _parseMemInfoLine(String line) {
    final tokens = line.split(RegExp(r'\s+'));
    if (tokens.length > 2) {
      final value = int.tryParse(tokens[tokens.length - 2]);
      if (value != null) {
        return _calculateMemorySize(value, tokens.last);
      }
    }
    // Parse gone haywire, abort
    return -1;
  }

  const meminfoPath = '/proc/meminfo';
  final file = File(meminfoPath);
  // ignore: avoid_slow_async_io
  if (await file.exists()) {
    final infoLines = await file.readAsLines();
    int total; // total memory in MB
    int free; // toal free memory in MB
    for (final line in infoLines) {
      if (line.toLowerCase().contains('memavailable')) {
        free = _parseMemInfoLine(line);
      }
      if (line.toLowerCase().contains('memtotal')) {
        total = _parseMemInfoLine(line);
      }
    }
    // Make sure we have values for both and return the params
    if (total > 0 && free > 0) {
      final percentUsed = 1 - (free / total);
      return {
        'memtotal': total.toString(),
        'memuse': percentUsed.toStringAsFixed(2),
      };
    }
  }
  return null;
}
