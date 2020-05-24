import 'dart:io';
import 'dart:typed_data';

import 'package:file_chooser/file_chooser.dart';

Future<bool> saveFile(String name, Uint8List bytes) async {
  var result = await showSavePanel(suggestedFileName: name);
  if (result.paths.isNotEmpty) {
    var file = File(result.paths.first);
    await file.writeAsBytes(bytes, mode: FileMode.writeOnly);
    return true;
  }
  return false;
}
