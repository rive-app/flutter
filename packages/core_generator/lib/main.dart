import 'dart:io';
import 'package:core_generator/runtime_mutator.dart';
import 'package:core_generator/src/configuration.dart';
import 'package:core_generator/src/field_types/initialize.dart';
import 'package:dart_style/dart_style.dart';

import 'src/definition.dart';

final formatter = DartFormatter();

void main(List<String> arguments) {
  var config = Configuration.fromArguments(arguments);

  initializeFields();

  Directory(config.path).list(recursive: true).listen((entity) {
    if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
      Definition(config, entity.path.substring(config.path.length));
    }
  }, onDone: () {
    if (config.isVerbose) {
      print("Defined fields are $fields");
    }
    Definition.generate(config);
  });

  // When we're running for runtime, we also want to copy from runtimeCoreFolder
  // to our output folder.
  if (config.isRuntime) {
    List<String> movePackages = ['fractional', 'utilities'];

    var fromFolder = '${config.runtimeCoreFolder}lib/';
    var subLength = fromFolder.length;
    var base = '${config.output}lib/${config.packageName}_core/';
    if (Directory(base).existsSync()) {
      Directory(base).deleteSync(recursive: true);
    }
    Directory(fromFolder).list(recursive: true).listen((entity) {
      if (entity is File && entity.path.toLowerCase().endsWith('.dart')) {
        var subPath = entity.path.substring(subLength);
        if (subPath.startsWith('src/generated/')) {
          return;
        }

        // Convert the file.
        var contents = entity.readAsStringSync();

        contents = contents.replaceAll(
            "import 'package:rive_core/rive_file.dart';", "");

        contents =
            contents.replaceAll('Base<RiveFile>', 'Base<RuntimeArtboard>');

        // Strip out editor-only
        contents = contents.replaceAll(
            RegExp('\/\/ -> editor-only.*?\/\/ <- editor-only',
                multiLine: true, dotAll: true),
            '');

        contents = contents.replaceAllMapped(
            RegExp('\/\/ -> runtime-only(.*?)\/\/ <- runtime-only',
                multiLine: true, dotAll: true), (match) {
          return match.group(1).toString().replaceAll(
              RegExp(
                '^\\s*\/\/',
                multiLine: true,
                dotAll: true,
              ),
              '');
        });

        // Remove Base<RiveFile>
        contents =
            contents.replaceAll('Base<RiveFile>', 'Base<RuntimeArtboard>');

        var package = config.packageName;
        contents = contents.replaceAll(
            ' \'package:${package}_core/src/generated',
            ' \'package:${package}/src/generated');
        contents = contents.replaceAll(' \'package:${package}_core/',
            ' \'package:${package}/${package}_core/');
        contents = contents.replaceAll(
            ' \'package:core/', ' \'package:${package}/src/core/');
        for (final moved in movePackages) {
          contents = contents.replaceAll(
              ' \'package:$moved/', ' \'package:${package}/src/$moved/');
        }

        var mutator = RuntimeMutator();
        contents = mutator.mutate(contents.toString(), [
          Mutation('Id', 'int'),
          Mutation('FractionalIndex', 'int'),
          Mutation('animateDouble', 'setDouble'),
        ]);

        var formattedCode = formatter.format(contents.toString());
        if (formattedCode.trim().length == 0) {
          // Don't output the file if it's empty.
          return;
        }

        var file =
            File('${config.output}lib/${config.packageName}_core/$subPath');
        file.createSync(recursive: true);
        file.writeAsStringSync(formattedCode);

        // file.writeAsStringSync(contents)

        // entity.copy('${config.output}lib/${config.packageName}_core/$subPath');

      }
    }, onDone: () {
      for (final package in movePackages) {
        movePackage('${config.output}../$package/lib',
            '${config.output}lib/src/$package');
      }
    });
  }
}

void movePackage(String from, String to) {
  if (Directory(to).existsSync()) {
    Directory(to).deleteSync(recursive: true);
  }
  var baseLength = from.length;
  Directory(from).list(recursive: true).listen((entity) {
    if (entity is File) {
      var destination = '$to${entity.path.substring(baseLength)}';
      // Convert the file.
      var contents = entity.readAsStringSync();

      // Strip out editor-only
      var matched = RegExp(
              '\/\/ -> include-runtime(.*?)\/\/ <- include-runtime',
              multiLine: true,
              dotAll: true)
          .allMatches(contents);
      contents = matched.fold('', (prev, match) => prev + match.group(1));
      if (contents.trim().isNotEmpty) {
        contents = formatter.format(contents);
        File(destination)
          ..createSync(recursive: true)
          ..writeAsStringSync(contents);
      }
    }
  }, onDone: () {});
}
