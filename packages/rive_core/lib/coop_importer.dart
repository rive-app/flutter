// -> editor-only
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:rive_core/rive_file.dart';
import 'package:core/coop/coop_file.dart';
import 'package:meta/meta.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';

final _log = Logger('Coop Importer');

class CoopImporter {
  final RiveFile core;

  CoopImporter({
    @required this.core,
  });

  bool import(Uint8List data) {
    var coop = CoopFile();
    if (!coop.deserialize(BinaryReader.fromList(data))) {
      _log.severe('Failed to deserialize coop file.');
      return false;
    }
    core.receiveCoopChanges(coop.toChangeSet());
    core.onConnected();
    return true;
  }
}
// <- editor-only
