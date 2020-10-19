import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:core/id.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
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
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/shape_tool.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:utilities/utilities.dart';

abstract class RiveClipboard {
  RiveClipboard._();
  factory RiveClipboard.copy(OpenFileContext file) {
    assert(file != null, 'can\'t copy from null file');
    var keyFrameManager = file.keyFrameManager.value;
    if (keyFrameManager != null && keyFrameManager.selection.value.isNotEmpty) {
      return _RiveKeyFrameClipboard(keyFrameManager.selection.value);
    } else {
      return _RiveHierarchyClipboard(file);
    }
  }
  bool paste(OpenFileContext file);
}

class _RiveKeyFrameClipboard extends RiveClipboard {
  Uint8List bytes;
  final List<Id> keyedObjectIds = [];
  _RiveKeyFrameClipboard(HashSet<KeyFrame> keyFrames) : super._() {
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

  @override
  bool paste(OpenFileContext file) {
    // ToC: For now assume that the we're pasting from one valid Rive to
    // another. If we ever paste across different versions of Rive, we can
    // consider building this up properly. It just means that if a bad field or
    // object is encountered, the entire paste is botched.
    final propertyToField = HashMap<int, CoreFieldType>();

    var core = file.core;
    var keyFrameManager = file.keyFrameManager.value;
    var animationManager = file.editingAnimationManager.value;

    // Can't paste keyframes if we're not in animation mode.
    if (!core.isAnimating || keyFrameManager == null) {
      return false;
    }
    var reader = BinaryReader.fromList(bytes);
    var interpolatorCount = reader.readVarUint();
    var interpolators = List<Core>(interpolatorCount);

    core.batchAdd(() {
      for (int i = 0; i < interpolatorCount; i++) {
        var interpolator =
            interpolators[i] = core.readRuntimeObject(reader, propertyToField);
        if (interpolator is Interpolator) {
          core.addObject(interpolator);
        }
      }

      var idRemap = RuntimeIdRemap(core.idType, core.uintType);
      var remaps = <RuntimeRemap>[idRemap];

      int minTime = double.maxFinite.toInt();
      List<KeyFrame> addedKeyFrames = [];
      var animation = keyFrameManager.animation;
      var keyedObjectCount = reader.readVarUint();
      for (int i = 0; i < keyedObjectCount; i++) {
        var keyedObject = core.readRuntimeObject<KeyedObject>(
            reader, propertyToField, remaps);
        if (keyedObject == null) {
          continue;
        }
        // Original keyed object for the id we're trying to key.
        var existingObjectToKey = core.resolve<Core>(keyedObjectIds[i]);
        // Make sure it is actually keyed in this animation (use could've
        // changed animation).
        if (animation.getKeyed(existingObjectToKey) != null) {
          keyedObject = animation.getKeyed(existingObjectToKey);
        } else {
          // The animation didn't already key this object, so let's pipe in our
          // new keyedObject to it.
          core.addObject(keyedObject);
          keyedObject.animationId = keyFrameManager.animation.id;
        }
        var numKeyedProperties = reader.readVarUint();
        for (int k = 0; k < numKeyedProperties; k++) {
          var keyedProperty = core.readRuntimeObject<KeyedProperty>(
              reader, propertyToField, remaps);
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
            var keyframe = core.readRuntimeObject<KeyFrame>(
                reader, propertyToField, remaps);
            if (keyframe.frame < minTime) {
              minTime = keyframe.frame;
            }
            addedKeyFrames.add(keyframe);
            core.addObject(keyframe);
            keyframe.keyedPropertyId = keyedProperty.id;
          }
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
      for (final keyframe in addedKeyFrames) {
        keyframe.frame = keyframe.frame - minTime + animationManager.frame;
      }
    });

    return true;
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

    for (final component in topComponents) {
      // This is a top level component, add it and any of its children to the
      // copy set.
      copiedComponents.add(component);
      if (component is ContainerComponent) {
        component.forEachChild((child) {
          copiedComponents.add(child);
          return true;
        });
      }
    }

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
