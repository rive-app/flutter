// -> editor-only
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_draw_order.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';
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
        var idRemap = RuntimeIdRemap(core.idType, core.intType);
        var drawOrderRemap =
            DrawOrderRemap(core.fractionalIndexType, core.intType);

        var remaps = <RuntimeRemap>[idRemap, drawOrderRemap];
        var artboard = core.readRuntimeObject<Artboard>(reader, remaps);
        core.addObject(artboard);
        var numObjects = reader.readVarUint();
        var objects = List<Core<RiveCoreContext>>(numObjects);
        for (int i = 0; i < numObjects; i++) {
          Core<RiveCoreContext> object = core.readRuntimeObject(reader, remaps);
          objects[i] = object;
          if (object != null) {
            core.addObject(object);
          }
        }

        // Animations also need to reference objects, so make sure they get read
        // in before the hierarchy resolves (batch add completes).
        var numAnimations = reader.readVarUint();
        for (int i = 0; i < numAnimations; i++) {
          var animation = core.readRuntimeObject<Animation>(reader, remaps);
          if (animation == null) {
            continue;
          }
          core.addObject(animation);
          animation.artboardId = artboard.id;

          var numKeyedObjects = reader.readVarUint();
          for (int j = 0; j < numKeyedObjects; j++) {
            var keyedObject =
                core.readRuntimeObject<KeyedObject>(reader, remaps);
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
                  core.readRuntimeObject<KeyedProperty>(reader, remaps);
              if (keyedProperty == null) {
                continue;
              }
              core.addObject(keyedProperty);
              keyedProperty.keyedObjectId = keyedObject.id;

              var numKeyframes = reader.readVarUint();
              
              for (int l = 0; l < numKeyframes; l++) {
                var keyframe = core.readRuntimeObject<KeyFrame>(reader, remaps);
                core.addObject(keyframe);
                keyframe.keyedPropertyId = keyedProperty.id;
                if (keyframe is KeyFrameDrawOrder) {
                  keyframe.readRuntimeValues(core, reader, idRemap);
                }
              }
            }
          }
        }

        // Patch up the draw order.
        drawOrderRemap.remap(core);

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

class RuntimeIdRemap extends RuntimeRemap<int, Id> {
  RuntimeIdRemap(
      CoreFieldType<Id> fieldType, CoreFieldType<int> runtimeFieldType)
      : super(fieldType, runtimeFieldType);
  @override
  bool add(Core<CoreContext> object, int propertyKey, BinaryReader reader) {
    properties.add(RuntimeRemapProperty<int>(
        object, propertyKey, runtimeFieldType.deserialize(reader)));
    return true;
  }
}

class DrawOrderRemap extends RuntimeRemap<int, FractionalIndex> {
  DrawOrderRemap(CoreFieldType<FractionalIndex> fieldType,
      CoreFieldType<int> runtimeFieldType)
      : super(fieldType, runtimeFieldType);

  @override
  bool add(Core<CoreContext> object, int propertyKey, BinaryReader reader) {
    if (propertyKey != DrawableBase.drawOrderPropertyKey) {
      return false;
    }
    properties.add(RuntimeRemapProperty<int>(
        object, propertyKey, runtimeFieldType.deserialize(reader)));
    return true;
  }

  void remap(RiveCoreContext core) {
    var list = properties.toList(growable: false);
    list.sort((a, b) => a.value.compareTo(b.value));
    _ImportDrawOrderHelper helper = _ImportDrawOrderHelper(list
        .map((item) => item.object)
        .toList(growable: false)
        .cast<Drawable>());
    helper.validateFractional();
  }
}

class _ImportDrawOrderHelper extends FractionallyIndexedList<Drawable> {
  _ImportDrawOrderHelper(List<Drawable> values) : super(values: values);
  @override
  FractionalIndex orderOf(Drawable value) => value.drawOrder;

  @override
  void setOrderOf(Drawable value, FractionalIndex order) {
    value.drawOrder = order;
  }
}

// <- editor-only
