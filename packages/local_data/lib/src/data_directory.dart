import 'dart:io';
import 'package:path_provider/path_provider.dart';

Directory _macosSupportDir;

/// Get a local data directory where we can read/write files.
Future<Directory> dataDirectory(String dirName) async {
  Directory dir;
  if (Platform.isMacOS) {
    // path = '${Platform.environment['HOME']}/.config/$dirName';
    // We can assume that the directory exists? Assume Apple
    // creates this for us, otherwise security hole?
    _macosSupportDir ??= await getApplicationSupportDirectory();
    dir = Directory('${_macosSupportDir.path}/$dirName');
  } else if (Platform.isLinux) {
    dir = Directory('${Platform.environment['HOME']}/.config/$dirName');
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
