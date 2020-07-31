import 'dart:typed_data';

import 'src/load_file_native.dart'
    if (dart.library.html) 'src/load_file_web.dart';

class LoadFile {
  /// Bring up a file navigator and grab some bytes.
  static Future<Uint8List> getUserFile(List<String> extensions) =>
      userFile(extensions);
}
