// -> editor-only
import 'dart:typed_data';

import 'package:rive_core/rive_file.dart';
import 'package:meta/meta.dart';

class CoopImporter {
  final RiveCoreContext core;

  CoopImporter({
    @required this.core,
  });

  bool import(Uint8List data) {
    return true;
  }
}
// <- editor-only
