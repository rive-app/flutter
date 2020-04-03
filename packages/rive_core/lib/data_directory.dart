import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Get a local data directory where we can read/write files.
Future<Directory> dataDirectory(String dirName) async {
  print('Getting directory');
  Directory dir;
  if (Platform.isMacOS || Platform.isLinux) {
    // path = '${Platform.environment['HOME']}/.config/$dirName';
    // We can assume that the directory exists? Assume Apple
    // creates this for us, otherwise security hole?
    print('Getting Mac directory: ${await getApplicationSupportDirectory()}');
    return getApplicationSupportDirectory();
  } else if (Platform.isWindows) {
    dir =
        Directory('${Platform.environment['UserProfile']}\\.config\\$dirName');
  } else {
    var directory = await getApplicationDocumentsDirectory();
    dir = Directory('${directory.path}/$dirName');
  }
  if (!await dir.exists()) {
    dir = await dir.create();
  }
  return dir;
}
