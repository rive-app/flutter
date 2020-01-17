// import 'package:core/coop/coop_server.dart';
import 'package:args/args.dart';
import 'package:coop_server_library/server.dart';

const String dataFolder = 'data-folder';

void main(List<String> arguments) async {
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
