import 'dart:typed_data';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/services.dart';

Future<Uint8List> userFile(List<String> extensions) async {
  FileChooserResult result = await showOpenPanel(
    allowedFileTypes: [
      FileTypeFilterGroup(
        fileExtensions: extensions,
      )
    ],
    canSelectDirectories: false,
    allowsMultipleSelection: false,
    confirmButtonText: 'Select',
  );
  if (result.paths.isEmpty) {
    return null;
  } else {
    var byteData = await rootBundle.load(result.paths.first);
    return byteData.buffer.asUint8List();
  }
}
