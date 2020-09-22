// -> editor-only
import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/id.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_core_field_type.dart';
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
    CoreDoubleType.max32Bit = true;
    var backboards = core.objectsOfType<Backboard>();
    if (backboards.isEmpty) {
      _log.severe('No backboards in file.');
      return null;
    }

    // Build up a table of contents for the field types.
    final propertyToField = HashMap<int, CoreFieldType>();

    // Find the backboard, this is the first thing we write into the file.
    var contentsWriter = BinaryWriter();
    var backboard = backboards.first;
    backboard.writeRuntime(contentsWriter, propertyToField);

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
    contentsWriter.writeVarUint(exportArtboards.length);

    // Export artboards.
    for (final artboard in exportArtboards) {
      // Make sure everything is updated (ensures drawables are in order) before
      // exporting.
      artboard.advance(0.0);
      // Build a lookup table for components that are in this artboard.
      HashMap<Id, int> idToIndex = HashMap<Id, int>();
      // Find all the components that belong to this artboard.
      List<Component> artboardComponents = [];
      artboard.forEachChild((object) {
        if (object.exportsWith(artboard)) {
          artboardComponents.add(object);
        }
        return true;
      });

      // The artboard is always at the start of the components list. We add it
      // after building up the ordered components as the artboard itself may not
      // have a fractional index for order.
      artboardComponents.insert(0, artboard);

      // Components aren't the only thing that get stored in the artboard object
      // list. Interpolators and any other object that is referenced by Id that
      // may not inherit directly from Component is added to this list.
      Set<Core<RiveCoreContext>> artboardObjects =
          Set<Core<RiveCoreContext>>.from(artboardComponents);
      // Components are now in the artboard objects and they are sorted. Proceed
      // to add any other object that needs to export with the artboard directly
      // (meaning it's not wrapped in some parent like keyframes are with keyed
      // properties).

      // -> TODO: luigi - re-enable this when #1016 is fixed
      // We find objects that want to be exported in this list by having them
      // implement ExporterInfo and returning true to exportAsArtboardObject.
      // artboardObjects.addAll(core
      //     .objectsOfType<ExportRules>()
      //     .where((info) => info.exportAsContextObject)
      //     .cast<Core<RiveCoreContext>>());
      // <- TODO: luigi - re-enable this when #1016 is fixed

      // -> TODO: remove this when #1016 is fixed. This is basically iterating
      // all the keyframes in this artboard and making a unique set of cubic
      // that are needed at runtime. Remap all other cubics to the actual
      // exported ones.
      Set<CubicInterpolator> cubicInterpolators = {};
      Map<CubicInterpolator, int> interpolatorIndices = {};
      for (final animation in artboard.animations) {
        if (animation is LinearAnimation) {
          for (final keyedObject in animation.keyedObjects) {
            for (final keyedProperty in keyedObject.keyedProperties) {
              for (final keyframe in keyedProperty.keyframes) {
                // Right now these are only CubicInterpolators
                var interpolator = keyframe.interpolator;
                if (interpolator is CubicInterpolator) {
                  var cubic = interpolator as CubicInterpolator;
                  for (final otherCubic in cubicInterpolators) {
                    if (otherCubic.equalParameters(interpolator)) {
                      // Make sure to map this cubic to the actual exported one.
                      idToIndex[interpolator.id] =
                          interpolatorIndices[otherCubic];
                      // This matches an already exported cubic.
                      interpolator = otherCubic;
                      break;
                    }
                  }
                  if (!cubicInterpolators.contains(interpolator)) {
                    interpolatorIndices[cubic] = artboardObjects.length;
                    artboardObjects.add(cubic);
                    cubicInterpolators.add(cubic);
                  }
                }
              }
            }
          }
        }
      }
      // <- TODO: remove this when #1016 is fixed.

      var artboardObjectsList = artboardObjects.toList(growable: false);
      for (int i = 0; i < artboardObjectsList.length; i++) {
        var component = artboardObjectsList[i];
        // Map ids in order (at runtime components can be directly looked up by
        // index this way).
        idToIndex[component.id] = i;
      }

      // Write the number of objects in the artboard.
      contentsWriter.writeVarUint(artboardObjects.length);
      // Write each object.
      for (final object in artboardObjects) {
        object.writeRuntime(contentsWriter, propertyToField, idToIndex);
      }

      // Figure out which animations we're exporting.
      var artboardAnimations = artboard.animations.toSet();
      if (animations != null) {
        // We want a subset of the animations, make sure we only include the
        // requested ones that are on this artboard.
        artboardAnimations = artboardAnimations.intersection(animations);
      }

      // Export the number of animations, and the animations themselves.
      contentsWriter.writeVarUint(artboardAnimations.length);
      for (final animation in artboardAnimations) {
        animation.writeRuntime(contentsWriter, propertyToField, idToIndex);
      }
    }
    CoreDoubleType.max32Bit = false;

    // Now that we know what's in our contents, write out our header with it's
    // table of contents for the property keys.
    var headerWriter = BinaryWriter();
    // Write the header, start with fingerprint.
    RuntimeHeader.fingerprint.codeUnits.forEach(headerWriter.writeUint8);
    headerWriter.writeVarUint(RuntimeHeader.majorVersion);
    headerWriter.writeVarUint(RuntimeHeader.minorVersion);
    headerWriter.writeVarUint(info.ownerId);
    headerWriter.writeVarUint(info.fileId);

    final fieldToIndex = {
      RiveUintType: 0,
      RiveStringType: 1,
      RiveDoubleType: 2,
      RiveColorType: 3,
      RiveBoolType: 0,
    };

    int currentInt = 0;
    int currentBit = 0;
    List<int> bitArray = [];

    propertyToField.forEach((key, field) {
      headerWriter.writeVarUint(key);
      assert(fieldToIndex[field.runtimeType] != null);
      currentInt |= fieldToIndex[field.runtimeType] << currentBit;
      currentBit += 2;
      if (currentBit == 8) {
        bitArray.add(currentInt);
        currentBit = 0;
        currentInt = 0;
      }
    });
    headerWriter.writeVarUint(0);
    if (currentBit != 0) {
      bitArray.add(currentInt);
    }
    assert(bitArray.length == (propertyToField.length / 4).ceil());
    bitArray.forEach(headerWriter.writeUint32);

    var fileWriter =
        BinaryWriter(alignment: headerWriter.size + contentsWriter.size);
    fileWriter.write(headerWriter.uint8Buffer);
    fileWriter.write(contentsWriter.uint8Buffer);
    return fileWriter.uint8Buffer;
  }
}
// <- editor-only
