// -> editor-only
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/exceptions/rive_format_error_exception.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:meta/meta.dart';

class RuntimeImporter {
  final RiveCoreContext core;
  RuntimeHeader _header;
  RuntimeHeader get header => _header;
  Backboard _backboard;
  Backboard get backboard => _backboard;

  RuntimeImporter({
    @required this.core,
  });

  bool import(Uint8List data) {
    assert(_header == null, 'can only import once');
    var reader = BinaryReader.fromList(data);
    _header = RuntimeHeader.read(reader);

    core.batchAdd(() {
      _backboard = core.readRuntimeObject<Backboard>(reader);
      if (_backboard == null) {
        throw const RiveFormatErrorException(
            'expected first object to be a Backboard');
      }
      core.addObject(_backboard);
      int numArtboards = reader.readVarUint();
      for (int i = 0; i < numArtboards; i++) {
        // The properties we remap at runtime, currently only Ids. This whole
        // idRemap stuff should be stripped at runtime.
        var idRemap = RuntimeRemapId(core.idType, core.intType);

        var artboard = core.readRuntimeObject<Artboard>(reader, idRemap);
        core.addObject(artboard);
        var numObjects = reader.readVarUint();
        var objects = List<Core<RiveCoreContext>>(numObjects);
        for (int i = 0; i < numObjects; i++) {
          Core<RiveCoreContext> object =
              core.readRuntimeObject(reader, idRemap);
          objects[i] = object;
          if (object != null) {
            core.addObject(object);
          }
        }

        // Animations also need to reference objects, so make sure they get read
        // in before the hierarchy resolves (batch add completes).
        var numAnimations = reader.readVarUint();
        for (int i = 0; i < numAnimations; i++) {
          var animation = core.readRuntimeObject<Animation>(reader, idRemap);
          if (animation == null) {
            continue;
          }
          core.addObject(animation);
          animation.artboardId = artboard.id;

          var numKeyedObjects = reader.readVarUint();
          for (int j = 0; j < numKeyedObjects; j++) {
            var keyedObject =
                core.readRuntimeObject<KeyedObject>(reader, idRemap);
            if (keyedObject == null) {
              continue;
            }
            core.addObject(keyedObject);
            // Because we optimized out the animationIds, we need to reset these
            // before batchAdd completes so that onAddedDirty and onAdded have
            // the id to lookup. Runtimes won't need this as we'll directly add
            // the keyed object to the animation.
            // runtime: animation.addKeyedObject(keyedObject);
            keyedObject.animationId = animation.id;

            var numKeyedProperties = reader.readVarUint();
            for (int k = 0; k < numKeyedProperties; k++) {
              var keyedProperty =
                  core.readRuntimeObject<KeyedProperty>(reader, idRemap);
              if (keyedProperty == null) {
                continue;
              }
              core.addObject(keyedProperty);
              keyedProperty.keyedObjectId = keyedObject.id;

              var numKeyframes = reader.readVarUint();
              for (int l = 0; l < numKeyframes; l++) {
                var keyframe =
                    core.readRuntimeObject<KeyFrame>(reader, idRemap);
                if (keyframe == null) {
                  continue;
                }
                core.addObject(keyframe);
                keyframe.keyedPropertyId = keyedProperty.id;
              }
            }
          }
        }

        // Perform the id remapping.
        for (final remap in idRemap.properties) {
          core.setObjectProperty(
              remap.object, remap.propertyKey, objects[remap.value].id);
        }

        // Any component objects with no id map to the artboard.
        for (final object in objects) {
          if (object is Component && object.parentId == null) {
            object.parentId = artboard.id;
          }
        }
      }
    });

    return true;
  }
}
// <- editor-only
