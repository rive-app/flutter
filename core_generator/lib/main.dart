import 'dart:io';
import 'package:args/args.dart';
import 'package:core_generator/src/configuration.dart';
import 'package:core_generator/src/field_types/initialize.dart';

import 'src/definition.dart';



void main(List<String> arguments) {
  var config = Configuration.fromArguments(arguments);
  

  initializeFields();


  Directory(config.path).list(recursive: true).listen((entity) {
    if (entity is File) {
      Definition(config, entity.path.substring(config.path.length));
    }
  }, onDone: () {
    if (config.isVerbose) {
      print("Defined fields are $fields");
    }
    Definition.generate(config);
  });
}
