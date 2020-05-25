import 'dart:collection';
import 'dart:typed_data';

import 'package:core/id.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:meta/meta.dart';

final _log = Logger('RuntimeExporter');

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

  /// Generate the contents of the runtime file. Pass in [artboards] or
  /// [animations] to only export artboards and animations included in those
  /// sets.
  Uint8List export({
    Set<Artboard> artboards,
    Set<Animation> animations,
  }) {
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

    var backboards = core.objectsOfType<Backboard>();
    if (backboards.isEmpty) {
      _log.severe("No backboards in file.");
      return null;
    }

    // Find the backboard, this is the first thing we write into the file.
    var backboard = backboards.first;
    backboard.writeRuntime(writer);

    // We order the artboards such that the main artboards is the first one in
    // the file.
    var mainArtboard = backboard.mainArtboard ?? backboard.activeArtboard;
    var exportArtboards = core.objectsOfType<Artboard>().toList();
    if (mainArtboard != null) {
      exportArtboards.remove(mainArtboard);
      exportArtboards.insert(0, mainArtboard);
    }

    // Export only the requested artboards (if provided).
    if (artboards != null) {
      exportArtboards = exportArtboards
          .toSet()
          .intersection(artboards)
          .toList(growable: false);
    }

    // Write the number of artboards.
    writer.writeVarUint(exportArtboards.length);
    var allComponents = core.objectsOfType<Component>().toList();
    // Export artboards.
    for (final artboard in exportArtboards) {
      // Build a lookup table for components that are in this artboard.
      HashMap<Id, int> idToIndex = HashMap<Id, int>();
      // Find all the components that belong to this artboard.
      List<Component> artboardComponents = [];
      for (final object in allComponents) {
        if (object.artboard == artboard) {
          artboardComponents.add(object);
        }
      }
      // Components are exported in hierarchy order. This makes it so we don't
      // have to export the childOrder FractionalIndex. Note that it's ok to
      // sort them in a flat list like this as items with the same values are
      // presumably parented to something different, so in their individual
      // parent/child relationships they will still be in order.
      artboardComponents.sort((a, b) => a.childOrder.compareTo(b.childOrder));
      for (int i = 0; i < artboardComponents.length; i++) {
        var component = artboardComponents[i];
        // Map ids in order (at runtime components can be directly looked up by
        // index this way).
        idToIndex[component.id] = i;
      }

      // Write the core artboard object.
      artboard.writeRuntime(writer, idToIndex);
      // Write the number of components in the artboard.
      writer.writeVarUint(artboardComponents.length);
      // Write each component.
      for (final component in artboardComponents) {
        component.writeRuntime(writer, idToIndex);
      }
    }

    return writer.uint8Buffer;
  }
}
