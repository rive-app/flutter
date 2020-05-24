import 'dart:collection';
import 'dart:typed_data';

import 'package:core/id.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:meta/meta.dart';

enum RuntimePermissions { allowEditorImport }

class RuntimeFileInfo {
  final int ownerId;
  final int fileId;
  final int permissions;
  final Uint8List signature;

  bool hasAccess(RuntimePermissions permission) =>
      (permissions & permission.index) != 0;

  RuntimeFileInfo({
    @required this.ownerId,
    @required this.fileId,
    this.permissions = 0,
    this.signature,
  });
}

class RuntimeExporter {
  static const int majorVersion = 0;
  static const int minorVersion = 1;

  final RiveCoreContext core;
  final RuntimeFileInfo info;

  RuntimeExporter({
    @required this.core,
    @required this.info,
  });

  Uint8List export() {
    var writer = BinaryWriter();
    // Write the header, start with fingerprint.
    'RIVE'.codeUnits.forEach(writer.writeUint8);
    writer.writeVarUint(majorVersion);
    writer.writeVarUint(minorVersion);
    writer.writeVarUint(info.ownerId);
    writer.writeVarUint(info.fileId);
    writer.writeVarUint(info.permissions);
    var hasSignature = info.signature != null && info.signature.isNotEmpty;
    if (!hasSignature) {
      writer.writeVarUint(0);
    } else {
      writer.writeVarUint(info.signature.length);
      writer.write(info.signature);
    }

    // TODO: Build up lookup table
    HashMap<Id, int> lookup = HashMap<Id, int>();

    // Export artboards.
    for (final artboard in core.objectsOfType<Artboard>()) {
      artboard.writeRuntime(writer, lookup);
    }

    return writer.uint8Buffer;
  }
}
