import 'package:args/args.dart';

const String _verbose = 'verbose';
const String _definitionsFolder = 'definitions-folder';

class Configuration {
  final bool isVerbose;
  final Iterable<String> filenames;
  final String definitionsFolder;

  Configuration({
    this.isVerbose,
    this.filenames,
    this.definitionsFolder,
  });

  factory Configuration.fromArguments(List<String> arguments) {
    var parser = ArgParser()
      ..addFlag(_verbose, negatable: false, abbr: 'v')
      ..addOption(_definitionsFolder, abbr: 'd');

    var argResults = parser.parse(arguments);
    return Configuration(
      isVerbose: argResults[_verbose] as bool,
      filenames: argResults.rest.where((value) => value.endsWith('.riv')),
      definitionsFolder: argResults[_definitionsFolder] as String,
    );
  }
}
