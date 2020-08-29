import 'dart:io';
import 'package:dart_style/dart_style.dart';

final formatter = DartFormatter();

class InsertAnalysisComment {
  final String expression;
  final String comment;

  InsertAnalysisComment(this.expression, this.comment);
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Folder needs to be specified.');
    exit(1);
  }
  String directory = args.first;

  Map<String, List<String>> _changes = {};

  Process.run('flutter', ['analyze'], workingDirectory: directory)
      .then((result) {
    var lines = result.stdout.toString().split('\n');

    var removals = [
      // Remove unused imports
      ' • Unused import: (.*?) • (.*?):([0-9]+):([0-9]+) • unused_import\$',
      // Remove missing imports
      ' • (.*?) • (.*?):([0-9]+):([0-9]+) • uri_does_not_exist\$',
    ];
    for (final expression in removals) {
      var regex = RegExp(expression);
      for (final line in lines) {
        var match = regex.firstMatch(line);
        if (match == null) {
          continue;
        }
        var file = match[2];
        var lineNumber = int.parse(match[3]) - 1;
        _changes[file] ??=
            File('$directory/$file').readAsStringSync().split('\n');
        _changes[file][lineNumber] = null;
      }
    }
    // info • Don't reassign references to parameters of functions or methods • lib/src/rive_core/shapes/paint/trim_path_drawing.dart:18:5 • parameter_assignments
    var patches = [
      InsertAnalysisComment(
        ' • Use a setter for operations that conceptually change a '
            'property • (.*?):([0-9]+):([0-9]+) • '
            'use_setters_to_change_properties\$',
        '// ignore: use_setters_to_change_properties',
      ),
      InsertAnalysisComment(
        ' • Don\'t reassign references to parameters of functions or'
            ' methods • (.*?):([0-9]+):([0-9]+) • parameter_assignments\$',
        '// ignore: parameter_assignments',
      )
    ];
    for (final patch in patches) {
      var regex = RegExp(patch.expression);
      for (final line in lines) {
        var match = regex.firstMatch(line);
        if (match == null) {
          continue;
        }
        var file = match[1];
        var lineNumber = int.parse(match[2]) - 1;
        _changes[file] ??=
            File('$directory/$file').readAsStringSync().split('\n');
        _changes[file][lineNumber] =
            '    ' + patch.comment + '\n' + _changes[file][lineNumber];
      }
    }

    // Write changed files with lines removed.
    _changes.forEach((filename, lines) {
      var contents = lines.where((line) => line != null).join('\n');

      File('$directory/$filename')
          .writeAsStringSync(formatter.format(contents));
      // print('Fixed: $directory/$filename');
    });
  });
}
