// import 'package:core/coop/coop_server.dart';
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

  final parser = ArgParser()..addOption(dataFolder, abbr: 'd');

  var argResults = parser.parse(arguments);
  var path = argResults[dataFolder] as String;
  print("FOLDER $path");
  var server = RiveCoopServer();
  var result = await server.listen(
    port: 8000,
    options: {
      'data-dir': path,
    },
  );
  print('Server listened result $result.');
}
