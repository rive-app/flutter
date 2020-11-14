import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/id.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';
import 'package:rive_editor/widgets/common/converters/convert.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:utilities/utilities.dart';

bool _keyFramesBelongToSingleObject(HashSet<KeyFrame> keyframes) {
  Id objectId = keyframes.first.keyedProperty.keyedObject.objectId;

  return !keyframes
      .skip(1)
      .any((frame) => frame.keyedProperty.keyedObject.objectId != objectId);
}

bool _keyFramesBelongToSingleProperty(HashSet<KeyFrame> keyframes) {
  Id propertyId = keyframes.first.keyedPropertyId;

  return !keyframes.skip(1).any((frame) => frame.keyedPropertyId != propertyId);
}

abstract class RiveClipboard {
  RiveClipboard._();
  factory RiveClipboard.copy(OpenFileContext file) {
    assert(file != null, 'can\'t copy from null file');
    var keyFrameManager = file.keyFrameManager.value;
    if (keyFrameManager != null && keyFrameManager.selection.value.isNotEmpty) {
      // We're copying keyframes, now determine what kind of keyframe copy/paste
      // op it is.
      var keyframes = keyFrameManager.selection.value;

      // If any keyframes have a different objectId, we need a multi-object
      // clipboard (means we can only paste back to this same file and only back
      // to these same objects, no copying of keyframes across properties).
      if (_keyFramesBelongToSingleObject(keyframes)) {
        return _PropertyKeyFrameClipboard(file, keyframes);
      } else {
        return _MultiObjectKeyFrameClipboard(file, keyframes);
      }
    } else {
      return _RiveHierarchyClipboard(file);
    }
  }
  bool paste(OpenFileContext file);
}

abstract class _KeyFrameClipboard extends RiveClipboard {
  Uint8List bytes;
  final List<Id> keyedObjectIds = [];
  final int fileId;
  final int ownerId;

  _KeyFrameClipboard(OpenFileContext file, HashSet<KeyFrame> keyFrames)
      : fileId = file.fileId,
        ownerId = file.ownerId,
        super._() {
    var export = <KeyedObject, HashMap<KeyedProperty, HashSet<KeyFrame>>>{};

    var interpolators = <Core>{};
    for (final keyframe in keyFrames) {
      var kp = keyframe.keyedProperty;
      var ko = kp.keyedObject;
      if (keyframe.interpolator is Core) {
        interpolators.add(keyframe.interpolator as Core);
      }
      var exportKeyedObject =
          export[ko] ??= HashMap<KeyedProperty, HashSet<KeyFrame>>();
      var keyframes = exportKeyedObject[kp] ??= HashSet<KeyFrame>();
      keyframes.add(keyframe);
    }

    // Build up an idLookup table for the ids of the referenced interpolators to
    // their export key (an index in the interpolator list).
    var idLookup = HashMap<Id, int>();
    var interpolatorList = interpolators.toList();
    for (int i = 0; i < interpolatorList.length; i++) {
      var interpolator = interpolatorList[i];
      idLookup[interpolator.id] = i;
    }

    final propertyToField = HashMap<int, CoreFieldType>();
    var writer = BinaryWriter();
    writer.writeVarUint(interpolatorList.length);
    for (final interpolator in interpolatorList) {
      interpolator.writeRuntime(writer, propertyToField);
    }

    writer.writeVarUint(export.length);
    for (final keyedObject in export.keys) {
      keyedObjectIds.add(keyedObject.objectId);
      keyedObject.writeRuntimeSubset(
          writer, export[keyedObject], propertyToField, idLookup);
    }

    bytes = writer.uint8Buffer;
    return;
  }

  final _propertyToField = HashMap<int, CoreFieldType>();
  int _minTime = double.maxFinite.toInt();
  final List<KeyFrame> _addedKeyFrames = [];
  final List<RuntimeRemap> _remaps = [];

  bool pasteKeyedObject(
      EditingAnimationManager animationManager,
      KeyFrameManager keyFrameManager,
      BinaryReader reader,
      OpenFileContext file,
      Id existingObjectId,
      KeyedObject object);

  @override
  bool paste(OpenFileContext file) {
    var keyFrameManager = file.keyFrameManager.value;
    var core = file.core;
    var animationManager = file.editingAnimationManager.value;
    // Can't paste keyframes if we're not in animation mode.
    if (!core.isAnimating || keyFrameManager == null) {
      return false;
    }

    _propertyToField.clear();

    var reader = BinaryReader.fromList(bytes);
    var interpolatorCount = reader.readVarUint();
    var interpolators = List<Core>(interpolatorCount);

    bool pasteSuccess = true;
    core.batchAdd(() {
      for (int i = 0; i < interpolatorCount; i++) {
        var interpolator =
            interpolators[i] = core.readRuntimeObject(reader, _propertyToField);
        if (interpolator is Interpolator) {
          core.addObject(interpolator);
        }
      }

      var idRemap = RuntimeIdRemap(core.idType, core.uintType);
      _remaps.clear();
      _remaps.add(idRemap);

      _minTime = double.maxFinite.toInt();
      _addedKeyFrames.clear();
      var keyedObjectCount = reader.readVarUint();
      for (int i = 0; i < keyedObjectCount; i++) {
        var keyedObject = core.readRuntimeObject<KeyedObject>(
            reader, _propertyToField, _remaps);
        if (keyedObject == null) {
          continue;
        }

        if (!pasteKeyedObject(animationManager, keyFrameManager, reader, file,
            keyedObjectIds[i], keyedObject)) {
          pasteSuccess = false;
          return;
        }
      }
      // Perform the id remapping for the interpolators.
      for (final remap in idRemap.properties) {
        var id = interpolators[remap.value]?.id;
        if (id != null) {
          core.setObjectProperty(remap.object, remap.propertyKey, id);
        }
      }

      // Put them all relative to the playhead...
      for (final keyframe in _addedKeyFrames) {
        keyframe.frame = keyframe.frame - _minTime + animationManager.frame;
      }
    });

    return pasteSuccess;
  }
}

class _PropertyKeyFrameClipboard extends _KeyFrameClipboard {
  _PropertyKeyFrameClipboard(OpenFileContext file, HashSet<KeyFrame> keyFrames)
      : super(file, keyFrames);

  @override
  bool pasteKeyedObject(
      EditingAnimationManager animationManager,
      KeyFrameManager keyFrameManager,
      BinaryReader reader,
      OpenFileContext file,
      Id existingObjectId,
      KeyedObject keyedObject) {
    assert(keyedObjectIds.length == 1);
    var keyedObjectId = keyedObjectIds.first;

    var core = file.core;

    bool canPasteToOriginalObject =
        file.fileId == fileId && file.ownerId == ownerId;

    var selectedKeyFrames = keyFrameManager.selection.value;
    var targetObjects = HashSet<Component>();

    // If we're copying from one field (like X) and we have a single other
    // compatible field (like Y) selected, attempt copy/paste to that single
    // target property.
    KeyedProperty targetProperty;

    if (selectedKeyFrames.isEmpty && file.selection.isNotEmpty) {
      // No selected keyframes, but there are items selected on the stage, chose
      // those as targets for pasting.
      targetObjects.addAll(file.selection.items.mapWhereType<Component>(
          (item) => item is StageItem && item.component is Component
              ? item.component
              : null));
    } else if (selectedKeyFrames.isNotEmpty &&
        _keyFramesBelongToSingleObject(selectedKeyFrames)) {
      // paste to the single selected object in the timeline.
      var component = core.resolve<Component>(
          selectedKeyFrames.first.keyedProperty.keyedObject.objectId);
      if (component != null) {
        targetObjects.add(component);
        if (_keyFramesBelongToSingleProperty(selectedKeyFrames)) {
          targetProperty = selectedKeyFrames.first.keyedProperty;
        }
      }
    }

    // If there were no targetObjects, try pasting back to the original
    // (effectively making that the target object).
    if (targetObjects.isEmpty && canPasteToOriginalObject) {
      var originalObject = core.resolve<Component>(keyedObjectId);
      if (originalObject != null) {
        targetObjects.add(originalObject);
      }
    }
    if (targetObjects.isNotEmpty) {
      var animation = keyFrameManager.animation;
      var keyedPropertyCount = reader.readVarUint();

      var startOfProperties = reader.position;
      for (final targetObject in targetObjects) {
        // Make sure this object is keyed in the animation.
        KeyedObject keyedObject = animation.getKeyed(targetObject);

        reader.readIndex = startOfProperties;

        for (int i = 0; i < keyedPropertyCount; i++) {
          var keyedProperty = core.readRuntimeObject<KeyedProperty>(
              reader, _propertyToField, _remaps);

          if (keyedProperty == null) {
            continue;
          }
          // We're attempting to paste to a single compatible field. Validate
          // the backing field types for the properties match (X can paste to
          // Y because they're both double).
          var pasteToSingleField =
              keyedPropertyCount == 1 && targetProperty != null;

          if (pasteToSingleField &&
              core.coreType(targetProperty.propertyKey) !=
                  core.coreType(keyedProperty.propertyKey)) {
            continue;
          } else if (!pasteToSingleField &&
              !targetObject.hasProperty(keyedProperty.propertyKey)) {
            // The keyed property didn't load or it isn't a valid property for
            // this target object.
            continue;
          }
          InputValueConverter<double> converterFrom;
          InputValueConverter<double> converterTo;

          // When pasting to a single field, we already have the target keyed
          // property, which is presumably valid and setup correctly (already
          // has a matching KeyedObject, otherwise it wouldn't be in our
          // selection).
          if (pasteToSingleField) {
            // Make sure we use the target as the keyed property to parent our
            // incomining frames to.
            if (core.coreType(targetProperty.propertyKey) == core.doubleType) {
              converterFrom =
                  converterForProperty<double>(keyedProperty.propertyKey);
              converterTo =
                  converterForProperty<double>(targetProperty.propertyKey);
            }
            keyedProperty = targetProperty;
          } else {
            // If there wasn't a keyedObject, attempt to make one now that we
            // know we have a valid property keyframed for it.
            keyedObject ??= animation.makeKeyed(targetObject);

            if (keyedObject.getKeyed(keyedProperty.propertyKey) != null) {
              // This property is already keyed, make sure we tack on our
              // keyframes to the existing list.
              keyedProperty = keyedObject.getKeyed(keyedProperty.propertyKey);
            } else {
              // Add our newed up keyedProperty to the keyedObject as we
              // didn't already keyframe this property.
              core.addObject(keyedProperty);
              keyedProperty.keyedObjectId = keyedObject.id;
            }
          }

          var numKeyframes = reader.readVarUint();

          for (int l = 0; l < numKeyframes; l++) {
            var keyframe = core.readRuntimeObject<KeyFrame>(
                reader, _propertyToField, _remaps);
            if (keyframe.frame < _minTime) {
              _minTime = keyframe.frame;
            }
            _addedKeyFrames.add(keyframe);
            core.addObject(keyframe);
            keyframe.keyedPropertyId = keyedProperty.id;
            if (converterFrom != null) {
              KeyFrameDouble doublekeyFrame = keyframe as KeyFrameDouble;
              doublekeyFrame.value = converterTo.fromEditingValue(
                  converterFrom.toEditingValue(doublekeyFrame.value));
            }
          }
        }
      }
    }
    return true;
  }
}

class _MultiObjectKeyFrameClipboard extends _KeyFrameClipboard {
  _MultiObjectKeyFrameClipboard(
      OpenFileContext file, HashSet<KeyFrame> keyFrames)
      : super(file, keyFrames);

  @override
  bool pasteKeyedObject(
      EditingAnimationManager animationManager,
      KeyFrameManager keyFrameManager,
      BinaryReader reader,
      OpenFileContext file,
      Id existingObjectId,
      KeyedObject keyedObject) {
    var core = file.core;
    var animation = animationManager.animation;
    // Original keyed object for the id we're trying to key.
    var existingObjectToKey = core.resolve<Core>(existingObjectId);
    // Make sure it is actually keyed in this animation (user could've
    // changed animation).
    if (animation.getKeyed(existingObjectToKey) != null) {
      // ignore: parameter_assignments
      keyedObject = animation.getKeyed(existingObjectToKey);
    } else {
      // The animation didn't already key this object, so let's pipe in our
      // new keyedObject to it.
      core.addObject(keyedObject);
      keyedObject.objectId = existingObjectId;
      keyedObject.animationId = keyFrameManager.animation.id;
    }
    var numKeyedProperties = reader.readVarUint();
    for (int k = 0; k < numKeyedProperties; k++) {
      var keyedProperty = core.readRuntimeObject<KeyedProperty>(
          reader, _propertyToField, _remaps);
      if (keyedProperty == null) {
        continue;
      }
      // Figure out if we want to add th keyedProperty to core or use an
      // existing one.

      if (keyedObject.getKeyed(keyedProperty.propertyKey) != null) {
        // This property is already keyed, make sure we tack on our
        // keyframes to the existing list.
        keyedProperty = keyedObject.getKeyed(keyedProperty.propertyKey);
      } else {
        // Add our newed up keyedProperty to the keyedObject as we didn't
        // already keyframe this property.
        core.addObject(keyedProperty);
        keyedProperty.keyedObjectId = keyedObject.id;
      }

      var numKeyframes = reader.readVarUint();

      for (int l = 0; l < numKeyframes; l++) {
        var keyframe =
            core.readRuntimeObject<KeyFrame>(reader, _propertyToField, _remaps);
        if (keyframe.frame < _minTime) {
          _minTime = keyframe.frame;
        }
        _addedKeyFrames.add(keyframe);
        core.addObject(keyframe);
        keyframe.keyedPropertyId = keyedProperty.id;
      }
    }
    return true;
  }

  @override
  bool paste(OpenFileContext file) {
    if (file.fileId != fileId || file.ownerId != ownerId) {
      // Don't allow pasting multi-object keyframe copies into different files.
      return false;
    }
    return super.paste(file);
  }
}

Set<Component> _topSelection(OpenFileContext file) {
  var components = <Component>{};
  for (final item in file.selection.items) {
    if (item is StageItem && item.component is Component) {
      components.add(item.component as Component);
    }
  }

  return tops(components);
}

class _RiveHierarchyClipboard extends RiveClipboard {
  Uint8List bytes;
  final Set<Component> copiedComponents = {};

  /// Store a mapping of exported component to original parent it was exported
  /// from. Note that components that don't turn up in this mapping are parented
  /// to something else that was exported.
  final Map<int, Component> originalParent = {};

  _RiveHierarchyClipboard(OpenFileContext file) : super._() {
    var topComponents = _topSelection(file);

    Set<Component> unorderedCopiedComponents = {};
    for (final component in topComponents) {
      // This is a top level component, add it and any of its children to the
      // copy set.
      unorderedCopiedComponents.add(component);
      if (component is ContainerComponent) {
        component.forEachChild((child) {
          unorderedCopiedComponents.add(child);
          return true;
        });
      }
    }

    var artboard = unorderedCopiedComponents.isEmpty
        ? null
        : unorderedCopiedComponents.first.artboard;
    // Copied components must be in the same artboard.
    assert(!unorderedCopiedComponents
        .any((component) => component.artboard != artboard));

    // Iterate the artboard comopnents in order to add the copied components
    // into an ordered set. This ensures they get pasted in hierarchy order.
    artboard?.forAll((component) {
      if (unorderedCopiedComponents.contains(component)) {
        copiedComponents.add(component);
      }
      return true;
    });

    HashMap<Id, int> idToIndex = HashMap<Id, int>();
    int index = 0;
    for (final component in copiedComponents) {
      if (topComponents.contains(component)) {
        originalParent[index] = component.parent;
      }
      idToIndex[component.id] = index++;
    }

    // Don't actually use this here, but we need to play nice with our
    // serializer.
    final propertyToField = HashMap<int, CoreFieldType>();
    var writer = BinaryWriter();
    writer.writeVarUint(copiedComponents.length);
    for (final component in copiedComponents) {
      component.writeRuntime(writer, propertyToField, idToIndex);
    }
    bytes = writer.uint8Buffer;
  }

  @override
  bool paste(OpenFileContext file) {
    // ToC: For now assume that the we're pasting from one valid Rive to
    // another. If we ever paste across different versions of Rive, we can
    // consider building this up properly. It just means that if a bad field or
    // object is encountered, the entire paste is botched.
    final propertyToField = HashMap<int, CoreFieldType>();

    var originalParents = originalParent.values.toSet();
    var topSelectedComponents = _topSelection(file);

    var topParentsOfSelection = <Component>{};
    for (final component in topSelectedComponents) {
      topParentsOfSelection.add(component.parent);
    }

    var pasteToOriginalParents =
        originalParents.difference(topParentsOfSelection).isEmpty;

    Component pasteDestination = topSelectedComponents.isEmpty
        ? file.backboard.activeArtboard
        : topSelectedComponents.first;
    // topParentsOfSelection.first ?? topSelectedComponents.first;
    var pasteDestinationParent =
        pasteDestination.parent ?? file.backboard.activeArtboard;
    // if (selectedItem is StageItem &&
    //     selectedItem.component is Component &&
    //     !copiedComponents.contains(selectedItem.component)) {
    //   pasteDestination = selectedItem.component as Component;
    // } else {
    //   pasteDestination = file.core.backboard.activeArtboard;
    // }

    var reader = BinaryReader.fromList(bytes);
    var numObjects = reader.readVarUint();
    var core = file.core;

    var idRemap = RuntimeIdRemap(core.idType, core.uintType);
    var remaps = <RuntimeRemap>[idRemap];

    var targetArtboard = file.backboard.activeArtboard;
    var objects = List<Component>(numObjects);

    Map<Node, Vec2D> needsCentering = {};

    core.batchAdd(() {
      for (int i = 0; i < numObjects; i++) {
        var component =
            core.readRuntimeObject<Component>(reader, propertyToField, remaps);
        if (component != null) {
          objects[i] = component;
          core.addObject(component);
        }
      }

      // Perform the id remapping.
      for (final remap in idRemap.properties) {
        var id = objects[remap.value]?.id;
        if (id != null) {
          core.setObjectProperty(remap.object, remap.propertyKey, id);
        }
      }

      // Any component objects with no id map to the pasteDestination.
      for (int i = 0; i < objects.length; i++) {
        final object = objects[i];
        if (object is Component && object.parentId == null) {
          if (object is Artboard) {
            // Intentionally empty, artboard has no parent.
          } else if (pasteToOriginalParents) {
            // Go look up the parent..
            object.parentId = (originalParent[i] ?? pasteDestination).id;
          } else {
            // At some point we need to move this logic into the class hierarchy
            // so components can more generally handle their pasting rules.
            // We're keeping it here for now to SIP the clipboard logic which is
            // very much in flux.
            var toCenter = object;
            if (object is PathBase) {
              if (pasteDestination is ShapeBase) {
                object.parentId = pasteDestination.id;
              } else if (pasteDestination is PathBase) {
                object.parentId = pasteDestinationParent.id;
              } else {
                var shape = ShapeTool.makeShape(targetArtboard, object as Path,
                    addToParent: false);
                shape.parentId = pasteDestinationParent.id;
                var niceName = object.name
                    .replaceAll(RegExp('path', caseSensitive: false), '')
                    .trim();
                shape.name = '$niceName Shape';
                toCenter = shape;
              }
            } else {
              object.parentId = pasteDestinationParent.id;
            }
            if (toCenter is Node && pasteDestination is Node) {
              // Get world center of paste target before any new objects get
              // used to recompute bounds (basically bounds at paste).
              var localCenter =
                  AABB.center(Vec2D(), pasteDestination.localBounds);
              // Store the world center with the item that later needs to be
              // centered at that world coordinate.
              needsCentering[toCenter] = Vec2D.transformMat2D(
                  Vec2D(), localCenter, pasteDestination.worldTransform);
            }
          }
        }
      }
    });

    // Advance so we have valid bounds.
    targetArtboard.advance(0);

    // Iterate all objects that need centering.
    for (final node in needsCentering.keys) {
      // Get the target (center in world space) of this object.
      var target = needsCentering[node];

      // Get target center in local space.
      var toLocal = Mat2D();
      if (!Mat2D.invert(toLocal, (node.parent as Node).worldTransform)) {
        Mat2D.identity(toLocal);
      }

      // This is our center in local space.
      Vec2D center = Vec2D.transformMat2D(Vec2D(), target, toLocal);

      // Compute our local bounds.
      var nodeTransformedBounds = node.localBounds.transform(node.transform);
      // Get our individual center in local bounds.
      var nodeCenterTransformed = AABB.center(Vec2D(), nodeTransformedBounds);
      // Compute offset to transformed local center.
      var toNodeCenter =
          Vec2D.subtract(Vec2D(), nodeCenterTransformed, node.translation);

      // Move node to the local center, minus the computed offset to our
      // individual center.
      node.x = center[0] - toNodeCenter[0];
      node.y = center[1] - toNodeCenter[1];
    }

    // Finally select the firs of the newly added items.
    var selection = <StageItem>{};
    for (final component in _onlyParents(objects)) {
      // Select only stageItems that have been added to the stage.
      if (component == null ||
          component.stageItem == null ||
          component.stageItem.stage == null) {
        continue;
      }
      selection.add(component.stageItem);
    }
    if (selection.isNotEmpty) {
      file.selection.selectMultiple(selection);
    }

    return true;
  }
}

/// Returns a set of only those items who have no parents within the same set
Set<Component> _onlyParents(Iterable<Component> components) => components
    .where((component) => !components.contains(component.parent))
    .toSet();
