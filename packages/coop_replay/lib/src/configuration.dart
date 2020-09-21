import 'package:args/args.dart';

const String _verbose = 'verbose';
const String _definitionsFolder = 'definitions-folder';
const String _changesetsFolder = 'changesets';
const String _revision = 'revision';
const String _maxChangeset = 'max';

class Configuration {
  final bool isVerbose;
  final String changesetsFolder;
  final int changesetMax;
  final String definitionsFolder;
  final String revisionFile;
  Configuration({
    this.isVerbose,
    this.changesetsFolder,
    this.changesetMax = 1,
    this.revisionFile,
    this.definitionsFolder,
  });

  factory Configuration.fromArguments(List<String> arguments) {
    var parser = ArgParser()
      ..addFlag(_verbose, negatable: false, abbr: 'v')
      ..addOption(_definitionsFolder, abbr: 'd')
      ..addOption(_changesetsFolder, abbr: 'c')
      ..addOption(_maxChangeset, abbr: 'm')
      ..addOption(_revision, abbr: 'r');

    var argResults = parser.parse(arguments);
    return Configuration(
      isVerbose: argResults[_verbose] as bool,
      changesetsFolder: argResults[_changesetsFolder] as String,
      changesetMax: argResults[_maxChangeset] != null
          ? int.parse(argResults[_maxChangeset] as String)
          : 0,
      definitionsFolder: argResults[_definitionsFolder] as String,
      revisionFile: argResults[_revision] as String,
    );
  }
}
