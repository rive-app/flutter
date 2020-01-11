import 'dart:io';
import 'package:args/args.dart';
import 'package:core_generator/src/field_types/initialize.dart';

import 'src/definition.dart';

const String verbose = 'verbose';
const String definitionsFolder = 'definitions-folder';
const String outputFolder = 'output-folder';
const String coreContext = 'core-context';
const String regenKeys = 'regen-keys';
const String basePath = './core_defs/';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag(verbose, negatable: false, abbr: 'v')
    ..addOption(definitionsFolder, abbr: 'd')
    ..addOption(outputFolder, abbr: 'o')
    ..addOption(coreContext, abbr: 'c')
    ..addFlag(regenKeys, negatable: false, abbr: 'r');

  var argResults = parser.parse(arguments);

  initializeFields();

  var path = argResults[definitionsFolder] as String;
  var output = argResults[outputFolder] as String;
  var cc = argResults[coreContext] as String;

  Directory(path).list(recursive: true).listen((entity) {
    if (entity is File) {
      Definition(path, entity.path.substring(path.length));
    }
  }, onDone: () {
    if (argResults[verbose] as bool) {
      print("Defined fields are $fields");
    }
    Definition.generate(output, cc, argResults[regenKeys] as bool);
  });
}
