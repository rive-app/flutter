import 'dart:typed_data';

import 'src/save_file_native.dart'
    if (dart.library.html) 'src/save_file_web.dart';

class FileSave {
  static Future<bool> save(String name, Uint8List bytes) =>
      saveFile(name, bytes);
}
