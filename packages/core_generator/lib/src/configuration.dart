import 'package:args/args.dart';

const String _verbose = 'verbose';
const String _definitionsFolder = 'definitions-folder';
const String _outputFolder = 'output-folder';
const String _package = 'package';
const String _coreContext = 'core-context';
const String _regenKeys = 'regen-keys';
const String _runtime = 'runtime';
const String _runtimeCoreFolder = 'runtime-core-folder';

/// Configuration for running the Core generator.
class Configuration {
  final String path;
  final String output;
  final String coreContextName;
  final String packageName;
  final bool regenerateKeys;
  final bool isVerbose;
  final bool isRuntime;
  final String runtimeCoreFolder;

  Configuration({
    this.path,
    this.output,
    this.coreContextName,
    this.packageName,
    this.regenerateKeys,
    this.isVerbose,
    this.isRuntime,
    this.runtimeCoreFolder,
  });

  factory Configuration.fromArguments(List<String> arguments) {
    var parser = ArgParser()
      ..addFlag(_verbose, negatable: false, abbr: 'v')
      ..addOption(_definitionsFolder, abbr: 'd')
      ..addOption(_package, abbr: 'p')
      ..addOption(_outputFolder, abbr: 'o')
      ..addOption(_coreContext, abbr: 'c')
      ..addFlag(_regenKeys, negatable: false, abbr: 'k')
      ..addFlag(_runtime, negatable: false, abbr: 'r')
      ..addOption(_runtimeCoreFolder, abbr: 'i');

    var argResults = parser.parse(arguments);

    return Configuration(
      path: argResults[_definitionsFolder] as String,
      output: argResults[_outputFolder] as String,
      coreContextName: argResults[_coreContext] as String,
      packageName: argResults[_package] as String,
      regenerateKeys: argResults[_regenKeys] as bool,
      isVerbose: argResults[_verbose] as bool,
      isRuntime: argResults[_runtime] as bool,
      runtimeCoreFolder: argResults[_runtimeCoreFolder] as String,
    );
  }
}
