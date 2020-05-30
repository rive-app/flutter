// -> editor-only
import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:core/export_rules.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:meta/meta.dart';

final _log = Logger('RuntimeExporter');

class RuntimeExporter {
  final RiveCoreContext core;
  final RuntimeHeader info;

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
    RuntimeHeader.fingerprint.codeUnits.forEach(writer.writeUint8);
    writer.writeVarUint(RuntimeHeader.majorVersion);
    writer.writeVarUint(RuntimeHeader.minorVersion);
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
        if (object.artboard == artboard &&
            // Don't add artboards to their own object list.
            object.coreType != ArtboardBase.typeKey &&
            // Don't include orphaned objects
            object.parent != null) {
          artboardComponents.add(object);
        }
      }
      // Components are exported in hierarchy order. This makes it so we don't
      // have to export the childOrder FractionalIndex. Note that it's ok to
      // sort them in a flat list like this as items with the same values are
      // presumably parented to something different, so in their individual
      // parent/child relationships they will still be in order.
      artboardComponents.sort((a, b) => a.childOrder.compareTo(b.childOrder));

      // Components aren't the only thing that get stored in the artboard object
      // list. Interpolators and any other object that is referenced by Id that
      // may not inherit directly from Component is added to this list.
      Set<Core<RiveCoreContext>> artboardObjects =
          Set<Core<RiveCoreContext>>.from(artboardComponents);
      // Components are now in the artboard objects and they are sorted. Proceed
      // to add any other object that needs to export with the artboard directly
      // (meaning it's not wrapped in some parent like keyframes are with keyed
      // properties).

      // We find objects that want to be exported in this list by having them
      // implement ExporterInfo and returning true to exportAsArtboardObject.
      artboardObjects.addAll(core
          .objectsOfType<ExportRules>()
          .where((info) => info.exportAsContextObject)
          .cast<Core<RiveCoreContext>>());

      var artboardObjectsList = artboardObjects.toList(growable: false);
      for (int i = 0; i < artboardObjectsList.length; i++) {
        var component = artboardObjectsList[i];
        // Map ids in order (at runtime components can be directly looked up by
        // index this way).
        idToIndex[component.id] = i;
      }

      // Write the core artboard object.
      artboard.writeRuntime(writer, idToIndex);
      // Write the number of objects in the artboard.

      writer.writeVarUint(artboardObjects.length);
      // Write each object.
      for (final object in artboardObjects) {
        object.writeRuntime(writer, idToIndex);
      }

      // Figure out which animations we're exporting.
      var artboardAnimations = artboard.animations.toSet();
      if (animations != null) {
        // We want a subset of the animations, make sure we only include the
        // requested ones that are on this artboard.
        artboardAnimations = artboardAnimations.intersection(animations);
      }

      // Export the number of animations, and the animations themselves.
      writer.writeVarUint(artboardAnimations.length);
      for (final animation in artboardAnimations) {
        animation.writeRuntime(writer, idToIndex);
      }
    }

    return writer.uint8Buffer;
  }
}
// <- editor-only
