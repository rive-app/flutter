import 'dart:io';

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

    var regex = RegExp(
        ' • Unused import: (.*?) • (.*?):([0-9]+):([0-9]+) • unused_import\$');
    for (final line in lines) {
      var match = regex.firstMatch(line);
      if (match == null) {
        continue;
      }
      var file = match[2];
      var lineNumber = int.parse(match[3]);
      _changes[file] ??=
          File('$directory/$file').readAsStringSync().split("\n");
      _changes[file][lineNumber] = null;
    }

    // Write changed files with lines removed.
    _changes.forEach((filename, lines) {
      File('$directory/$filename')
          .writeAsStringSync(lines.where((line) => line != null).join('\n'));
      // print('Fixed: $directory/$filename');
    });
  });
}
